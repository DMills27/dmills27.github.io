# _plugins/bibtex.rb
#
# Processes Pandoc-style citations in Jekyll posts using BibTeX and CSL.
#
# USAGE
# ─────
#   Write citations directly in post Markdown using the BibTeX key as the
#   cite alias — exactly as you would with \cite{key} in LaTeX:
#
#     A notable result [@smith2020].
#     Multiple sources [@smith2020; @jones2019].
#
#   Each citation renders as a linked numeric marker — [1], [2] — where the
#   number reflects the entry's position in the alphabetically sorted
#   References list appended at the end of the post.
#
#   The leading-minus suppress-author flag ([-@key]) is accepted for
#   compatibility but has no effect in numeric mode.
#
# BIBLIOGRAPHY FILE
# ─────────────────
#   Standard BibTeX format at _bib/bibliography.bib (default).
#   The key after @ is what you use in [@key] — same as LaTeX.
#
# CSL STYLE
# ─────────
#   Controls how bibliography entries are formatted.  "ieee" produces
#   numbered entries that match the [n] inline markers.
#   Browse styles at: https://www.zotero.org/styles
#
# CONFIGURATION (_config.yml)
# ────────────────────────────
#   bibtex:
#     bibliography: _bib/bibliography.bib
#     csl: _bib/style.csl        # optional custom CSL file
#     style: ieee                # built-in style name (fallback)
#
# REQUIREMENTS (Gemfile)
# ──────────────────────
#   gem 'bibtex-ruby'
#   gem 'citeproc-ruby'
#   gem 'csl-styles'

require 'bibtex'
require 'citeproc'
require 'csl/styles'

module Jekyll
  module BibtexPlugin
    # Matches [@key] or [@key1; @key2].  Leading - (suppress-author) accepted.
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
      BibTeX.open(path, filter: :latex)
    end

    def self.load_style(site)
      cfg      = site.config['bibtex'] || {}
      csl_rel  = cfg['csl']
      csl_path = csl_rel && File.join(site.source, csl_rel)
      if csl_path && File.exist?(csl_path)
        CSL::Style.load(csl_path)
      else
        cfg['style'] || 'ieee'
      end
    end

    # ── HTML splitting ───────────────────────────────────────────────────────

    PRE_CODE_RE = /(<pre[\s>][\s\S]*?<\/pre>|<code[\s>][\s\S]*?<\/code>)/i

    def self.split_preserve_code(html)
      html.split(PRE_CODE_RE)
    end

    # Return all cited keys in first-appearance order, skipping code blocks.
    def self.collect_cited_keys(html)
      keys = []
      split_preserve_code(html).each_with_index do |seg, i|
        next if i.odd?
        seg.scan(CITE_CLUSTER) { |m| extract_keys(m[0]).each { |k| keys |= [k] } }
      end
      keys
    end

    # ── Alphabetical sorting ─────────────────────────────────────────────────

    def self.author_sort_key(key, bibliography)
      entry = bibliography[key]
      return ['~', '', ''] unless entry

      raw = entry['author'].to_s
      first_author = raw.split(/\s+and\s+/i).first.to_s.strip
      last_name = if first_author.include?(',')
        first_author.split(',').first.strip
      else
        first_author.split.last.to_s
      end

      [last_name.downcase.gsub(/[^a-z0-9]/, ''), entry['year'].to_s, entry['title'].to_s.downcase]
    rescue
      ['~', '', '']
    end

    def self.sort_keys(cited_keys, bibliography)
      cited_keys.sort_by { |k| author_sort_key(k, bibliography) }
    end

    # ── Core processing ──────────────────────────────────────────────────────

    def self.process(output, bibliography, style)
      cited_keys = collect_cited_keys(output)
      return output.sub('<!-- bibtex-anchor -->', '') if cited_keys.empty?

      # sorted_keys defines the [n] numbering and the bibliography order.
      sorted_keys = sort_keys(cited_keys, bibliography)

      # Build a number lookup: key → 1-based position in the sorted list.
      number_for = {}
      sorted_keys.each_with_index { |k, i| number_for[k] = i + 1 }

      # Build processor with entries imported in sorted order.
      processor = CiteProc::Processor.new(style: style, format: 'html')
      sorted_keys.each do |key|
        entry = bibliography[key]
        if entry
          processor.import([entry.to_citeproc])
        else
          Jekyll.logger.warn('BibTeX:', "Undefined citation key: @#{key}")
        end
      end

      # Prime citeproc's internal numbering by rendering a citation for each
      # key in sorted order (output discarded).  Numeric CSL styles (ieee)
      # assign [1] to the first key cited, [2] to the second, etc.  Without
      # this step the bibliography entries would have no numbers.
      sorted_keys.each do |key|
        processor.render(:citation, [{ id: key }]) rescue nil
      end

      # ── Replace citation clusters with linked [n] markers ──────────────────
      segments = split_preserve_code(output)
      segments.map!.with_index do |seg, i|
        next seg if i.odd?

        seg.gsub(CITE_CLUSTER) do |full_match|
          keys  = extract_keys($1)
          valid = keys.select { |k| bibliography[k] && number_for.key?(k) }

          if valid.empty?
            %(<span class="citation-error" title="Undefined: #{keys.join(', ')}">#{full_match}</span>)
          else
            # Sort within the cluster by bibliography position.
            ordered = valid.sort_by { |k| number_for[k] }
            parts   = ordered.map { |k| %(<a href="#ref-#{k}">#{number_for[k]}</a>) }
            %(<span class="citation">[#{parts.join(', ')}]</span>)
          end
        end
      end
      output = segments.join

      # ── Build bibliography section ─────────────────────────────────────────
      valid_sorted = sorted_keys.select { |k| bibliography[k] }

      bib_html = if valid_sorted.any?
        entries = valid_sorted.map do |key|
          n          = number_for[key]
          entry_html = begin
            processor.render(:bibliography, [{ id: key }])&.first || key.to_s
          rescue StandardError => e
            Jekyll.logger.warn('BibTeX:', "Failed to render @#{key}: #{e.message}")
            key.to_s
          end
          # Inject [n] at the start of the csl-entry content.
          # If citeproc also added a number (ieee style), this may double it —
          # switch style to apa in _config.yml to avoid that.
          numbered_html = if entry_html.match?(/<div class="csl-entry">/)
            entry_html.sub(/<div class="csl-entry">/, %(<div class="csl-entry">[#{n}]\u00a0))
          else
            "[#{n}] #{entry_html}"
          end
          %(<div class="bibliography-entry" id="ref-#{key}">#{numbered_html}</div>)
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

    # ── Module-level state ───────────────────────────────────────────────────
    @bibliography = nil
    @style        = nil
    class << self
      attr_accessor :bibliography, :style
    end
  end
end

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
