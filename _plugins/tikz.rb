# _plugins/tikz.rb
#
# Compiles {% tikz name %} … {% endtikz %} blocks to SVG during Jekyll build.
#
# USAGE
# ─────
#   {% tikz my_diagram %}
#   \begin{tikzpicture}
#     \draw[->] (0,0) -- (2,0) node[right] {$x$};
#   \end{tikzpicture}
#   {% endtikz %}
#
#   Inline-injectable variant (SVG loaded via JS; supports CSS animation):
#   {% tikz my_diagram inline %}
#   ...
#   {% endtikz %}
#
# OUTPUT
# ──────
#   Standard mode : <img class="tikz-svg" src="/assets/tikz/name-<md5>.svg" …>
#   Inline mode   : <div class="tikz-inline" id="tikz-name"
#                        data-tikz-src="/assets/tikz/name-<md5>.svg"></div>
#                   (tikz-loader.js fetches and injects the SVG at runtime)
#
# CACHING
# ───────
#   The SVG filename includes an MD5 of the full LaTeX source.  If the file
#   already exists in assets/tikz/, compilation is skipped.  Delete the file
#   (or the whole assets/tikz/ directory) to force recompilation.
#
# REQUIREMENTS (provided by the Nix flake devShell)
# ──────────────────────────────────────────────────
#   pdflatex  — texlive scheme-basic
#   dvisvgm   — texlive dvisvgm package (--pdf flag, version ≥ 2.x)

require 'digest/md5'
require 'fileutils'
require 'open3'

module Jekyll
  module Tags
    class TikzBlock < Liquid::Block

      # LaTeX preamble shared by every TikZ diagram.
      # Uses the `standalone` class so the PDF/SVG is cropped to the content.
      # Add extra \usetikzlibrary entries here as needed.
      PREAMBLE = <<~'TEX'
        \documentclass{standalone}
        \usepackage{tikz}
        \usepackage{amsmath,amssymb,latexsym}
        \usetikzlibrary{
          arrows, arrows.meta, automata,
          backgrounds, calc, decorations.markings,
          fit, patterns, positioning,
          shapes, shapes.geometric
        }
      TEX

      def initialize(tag_name, markup, tokens)
        super
        parts   = markup.strip.split
        raw     = (parts.first || '').gsub(/[^\w_-]/, '').gsub(/\s+/, '_')
        @name   = raw.empty? ? 'tikz' : raw
        @inline = parts.include?('inline')
      end

      def render(context)
        body   = super.strip
        source = PREAMBLE + "\\begin{document}\n#{body}\n\\end{document}\n"
        md5    = Digest::MD5.hexdigest(source)

        site     = context.registers[:site]
        src_root = site.source

        # _tikz/ : intermediate files (tex, pdf, log, aux) — starts with _
        #          so Jekyll ignores it automatically; never committed.
        # assets/tikz/ : final SVG assets served to the browser.
        tikz_dir = File.join(src_root, '_tikz')
        svg_dir  = File.join(src_root, 'assets', 'tikz')
        FileUtils.mkdir_p(tikz_dir)
        FileUtils.mkdir_p(svg_dir)

        svg_name = "#{@name}-#{md5}.svg"
        svg_path = File.join(svg_dir, svg_name)
        tex_path = File.join(tikz_dir, "#{@name}-#{md5}.tex")
        web_src  = "/assets/tikz/#{svg_name}"

        unless File.exist?(svg_path)
          File.write(tex_path, source)
          ok = compile(tikz_dir, tex_path, svg_path)
          unless ok
            return <<~HTML
              <div class="tikz-error">
                <strong>TikZ error:</strong> compilation failed for
                <code>#{@name}</code>. Check the Jekyll build log for details.
              </div>
            HTML
          end
        end

        # Register the SVG as a Jekyll static file so it is copied to _site/
        # during the write phase.  Jekyll scans source files before the render
        # phase, so plugin-generated files are invisible to its normal scan;
        # adding them here ensures they appear in _site/assets/tikz/.
        # Guard against duplicates when jekyll --watch re-renders pages.
        unless site.static_files.any? { |f| f.relative_path == "/assets/tikz/#{svg_name}" }
          site.static_files << Jekyll::StaticFile.new(site, src_root, 'assets/tikz', svg_name)
        end

        if @inline
          # tikz-loader.js processes these divs on DOMContentLoaded.
          # Inline SVG enables CSS animation and parent-scoped style rules.
          %(<div class="tikz-inline" id="tikz-#{@name}" data-tikz-src="#{web_src}"></div>)
        else
          %(<img class="tikz-svg" src="#{web_src}" alt="TikZ: #{@name}" />)
        end
      end

      private

      def compile(work_dir, tex_path, svg_path)
        basename = File.basename(tex_path, '.tex')
        pdf_path = File.join(work_dir, "#{basename}.pdf")

        # ── Step 1: pdflatex → PDF ────────────────────────────────────────
        # -interaction=nonstopmode : don't stop on errors, write them to log
        # -halt-on-error           : exit with non-zero status on first error
        out1, st1 = Open3.capture2e(
          'pdflatex',
          '-interaction=nonstopmode',
          '-halt-on-error',
          "-output-directory=#{work_dir}",
          tex_path
        )

        unless st1.success? && File.exist?(pdf_path)
          Jekyll.logger.error('TikZ:', "pdflatex failed — #{File.basename(tex_path)}")
          # Print the last 10 lines of pdflatex output to help diagnose errors
          Jekyll.logger.error('TikZ:', out1.lines.last(10).join.chomp)
          return false
        end

        # ── Step 2: dvisvgm --pdf → SVG ──────────────────────────────────
        # --pdf       : treat input as PDF (not DVI)
        # --no-fonts  : replace font glyphs with SVG paths (portable; no
        #               system font needed by the browser)
        # --exact-bbox: use TeX's precise bounding-box data
        out2, st2 = Open3.capture2e(
          'dvisvgm',
          '--pdf',
          '--no-fonts',
          '--exact-bbox',
          "--output=#{svg_path}",
          pdf_path
        )

        unless st2.success? && File.exist?(svg_path)
          Jekyll.logger.error('TikZ:', "dvisvgm failed — #{File.basename(pdf_path)}")
          Jekyll.logger.error('TikZ:', out2.lines.last(10).join.chomp)
          return false
        end

        Jekyll.logger.info('TikZ:', "compiled #{File.basename(svg_path)}")
        true
      end
    end
  end
end

Liquid::Template.register_tag('tikz', Jekyll::Tags::TikzBlock)
