# _plugins/bibtex.rb
#
# Processes Pandoc-style citations in Jekyll posts using BibTeX and CSL.
#
# USAGE
# ─────
#   Write citations directly in post Markdown:
#
#     A notable result [@smith2020].
#     Multiple sources [@smith2020; @jones2019].
#
#   Cited references are automatically appended as a References section at the
#   end of the post (via the <!-- bibtex-anchor --> marker in post.html).
#
# BIBLIOGRAPHY FILE
# ─────────────────
#   Standard BibTeX format, placed at _bib/bibliography.bib (default).
#
# CSL STYLE
# ─────────
#   The csl-styles gem ships many built-in styles referenced by name:
#     apa, ieee, chicago-author-date, harvard-cite-them-right, …
#   To use a custom .csl file, set bibtex.csl in _config.yml.
#   Browse styles at: https://www.zotero.org/styles
#
# CONFIGURATION (_config.yml)
# ────────────────────────────
#   bibtex:
#     bibliography: _bib/bibliography.bib   # path relative to site root
#     csl: _bib/style.csl                   # optional custom CSL file
#     style: apa                            # built-in style name (fallback)
#
# REQUIREMENTS (Gemfile)
# ──────────────────────
#   gem 'bibtex-ruby'     — BibTeX file parsing
#   gem 'citeproc-ruby'   — CSL-based citation + bibliography rendering
#   gem 'csl-styles'      — bundled CSL style files

require 'bibtex'
require 'citeproc'
require 'csl/styles'

module Jekyll
  module BibtexPlugin
    # Matches Pandoc-style citation clusters: [@key] or [@key1; @key2].
    # Keys may contain word chars, hyphens, colons, and underscores.
    # A leading - suppresses the author name in author-date styles.
    CITE_CLUSTER = /\[(-?@[\w:_-]+(?:\s*;\s*-?@[\w:_-]+)*)\]/

    def self.extract_keys(cluster_interior)
      cluster_interior.scan(/-?@([\w:_-]+)/).flatten
    end

    # ── Initialisation ──────────────────────────────────────────────────────

    def self.load_bibliography(site)
      cfg  = site.config['bibtex'] || {}
      path = File.join(site.source, cfg['bibliography'] || '_bib/bibliography.bib')
      unless File.exist?(path)
        Jekyll.logger.warn('BibTeX:', "Bibliography not found: #{path}")
        return nil
      end
      # filter: :latex decodes LaTeX ligatures/escapes (---, \'{e}, …) to Unicode
      BibTeX.open(path, filter: :latex)
    end

    def self.load_style(site)
      cfg      = site.config['bibtex'] || {}
      csl_rel  = cfg['csl']
      csl_path = csl_rel && File.join(site.source, csl_rel)
      if csl_path && File.exist?(csl_path)
        CSL::Style.load(csl_path)
      else
        cfg['style'] || 'apa'
      end
    end

    # ── HTML splitting ───────────────────────────────────────────────────────

    # Split HTML into alternating segments: [normal, code, normal, code, …]
    # Odd-indexed segments are <pre> or <code> blocks — never touch those.
    PRE_CODE_RE = /(<pre[\s>][\s\S]*?<\/pre>|<code[\s>][\s\S]*?<\/code>)/i

    def self.split_preserve_code(html)
      html.split(PRE_CODE_RE)
    end

    # Collect all cited keys in first-appearance order, skipping code blocks.
    def self.collect_cited_keys(html)
      keys = []
      split_preserve_code(html).each_with_index do |seg, i|
        next if i.odd?
        seg.scan(CITE_CLUSTER) { |m| extract_keys(m[0]).each { |k| keys |= [k] } }
      end
      keys
    end

    # ── Core processing ──────────────────────────────────────────────────────

    def self.process(output, bibliography, style)
      cited_keys = collect_cited_keys(output)
      return output.sub('<!-- bibtex-anchor -->', '') if cited_keys.empty?

      # Build one processor for this post, seeded with only the cited entries.
      processor = CiteProc::Processor.new(style: style, format: 'html')
      cited_keys.each do |key|
        entry = bibliography[key]
        if entry
          processor.import([entry.to_citeproc])
        else
          Jekyll.logger.warn('BibTeX:', "Undefined citation key: @#{key}")
        end
      end

      # ── Replace citation clusters with formatted in-text spans ─────────────
      segments = split_preserve_code(output)
      segments.map!.with_index do |seg, i|
        next seg if i.odd?

        seg.gsub(CITE_CLUSTER) do |full_match|
          keys  = extract_keys($1)
          valid = keys.select { |k| bibliography[k] }

          if valid.empty?
            %(<span class="citation-error" title="Undefined: #{keys.join(', ')}">#{full_match}</span>)
          else
            rendered = render_citation(processor, valid, cited_keys)
            %(<span class="citation">#{rendered}</span>)
          end
        end
      end
      output = segments.join

      # ── Build bibliography section ─────────────────────────────────────────
      bib_items = cited_keys.filter_map do |key|
        next unless bibliography[key]
        html = render_bibliography_entry(processor, key)
        [key, html] if html
      end

      bib_html = if bib_items.any?
        entries = bib_items.map do |key, html|
          %(<div class="bibliography-entry" id="ref-#{key}">#{html}</div>)
        end.join("\n      ")

        <<~HTML
          <div class="bibliography">
            <h2 id="references">References</h2>
            <div class="bibliography-list">
              #{entries}
            </div>
          </div>
        HTML
      else
        ''
      end

      output.sub('<!-- bibtex-anchor -->', bib_html)
    end

    # ── Rendering helpers ────────────────────────────────────────────────────

    # Render an in-text citation cluster (one or more keys).
    # processor.render(:citation, items) expects a flat array of {id:} hashes
    # (each becomes a CitationItem); returns the formatted in-text string.
    # Falls back to [n] numeric markers if citeproc raises.
    def self.render_citation(processor, keys, cited_keys)
      processor.render(:citation, keys.map { |k| { id: k } })
    rescue StandardError
      nums = keys.map { |k| cited_keys.index(k) + 1 }
      "[#{nums.join(', ')}]"
    end

    # Render one bibliography entry from the shared processor.
    # processor.render(:bibliography, items) maps over the items array and
    # returns an Array<String>; we ask for just the one key and take .first.
    def self.render_bibliography_entry(processor, key)
      processor.render(:bibliography, [{ id: key }])&.first
    rescue StandardError => e
      Jekyll.logger.warn('BibTeX:', "Failed to render @#{key}: #{e.message}")
      nil
    end

    # ── Module-level state ───────────────────────────────────────────────────
    @bibliography = nil
    @style        = nil
    class << self
      attr_accessor :bibliography, :style
    end
  end
end

# Load bibliography and style after site reset — :after_reset fires after
# plugin files are required (conscientious_require runs in Site#reset before
# the hook is triggered), covering both the initial build and --watch reloads.
Jekyll::Hooks.register :site, :after_reset do |site|
  Jekyll::BibtexPlugin.bibliography = Jekyll::BibtexPlugin.load_bibliography(site)
  Jekyll::BibtexPlugin.style        = Jekyll::BibtexPlugin.load_style(site)
end

Jekyll::Hooks.register :posts, :post_render do |post|
  bib   = Jekyll::BibtexPlugin.bibliography
  style = Jekyll::BibtexPlugin.style
  next unless bib

  post.output = Jekyll::BibtexPlugin.process(post.output, bib, style)
end
