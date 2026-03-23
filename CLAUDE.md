# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Tale is a minimal Jekyll 4.x theme for storytellers, packaged as a Ruby gem (v0.2.1). It produces a static blog site with support for sidenotes, math rendering (MathJax), syntax highlighting (Highlight.js), hover popup annotations, reader highlight-comments (with localStorage persistence), and Anime.js v4 animations.

## Build & Development Commands

```bash
# Install dependencies
bundle install

# Build and serve locally (http://127.0.0.1:4000/)
bundle exec jekyll serve

# Build only (output to _site/)
bundle exec jekyll build
```

A Nix flake (`flake.nix`) is also available for reproducible builds on macOS (aarch64-darwin).

**Important:** `jekyll serve` only reads `_config.yml` once at startup. Changes to the config (e.g. `highlighter`, `kramdown` settings, `permalink`, `paginate`) will not take effect until the serve process is stopped and restarted.

## Architecture

### Content Flow

```
_posts/ + _pages/  →  _layouts/ (with _includes/)  →  _config.yml  →  _site/
```

### Layout Hierarchy

- **default.html** — Root HTML shell; loads head.html, navigation.html, footer.html, plus MathJax/Highlight.js/jQuery/custom scripts
- **home.html** — Extends default; paginated post listing
- **post.html** — Extends default; single post with metadata, tags, optional Disqus comments, prev/next navigation

### Styling

SCSS modules live in `_sass/tale/` with variables centralized in `_variables.scss`. Entry point is `assets/main.scss` → `tale.scss`. Mobile breakpoint at 600px. Output is compressed.

### JavaScript (`assets/js/`)

- **sidenotes.js** — Tufte-style sidenotes on desktop (≥ 600 px); falls back to standard footnote list on mobile. Supports rich footnote content: highlighted code blocks, images, and script-based animations via `cloneNode` + script re-execution. CSS in `_sass/tale/_sidenote.scss`.
- **highlight-code.js** — Syntax highlighting with line numbers via Highlight.js
- **popup-lite.js** — Rich hover popups triggered by `data-popup-title` on links; supports multiple concurrent popups, drag, pin, and Escape to close. CSS lives in `_sass/popup.scss`.
- **highlight-comments.js** — Medium-style reader annotations: select any text in `.post` to open a comment tooltip. Comments persist in `localStorage` keyed by pathname and are restored on reload. CSS lives in `_sass/highlight-comments.scss`.
- **anime.min.js** — Anime.js v4.3.6 UMD bundle (copied from `anime/dist/bundles/`). Exposes the global `anime` object; use inline `<script>` tags in post markdown to run animations.
- **tikz-loader.js** — Fetches TikZ SVG files and injects them inline into `.tikz-inline[data-tikz-src]` containers (produced by `{% tikz name inline %}`). Rewrites font class names per-container to prevent CSS conflicts when multiple SVGs are on the same page.
- **disqusLoader.js** — Lazy-loads Disqus comments

### Key Configuration (`_config.yml`)

The `_config.yml` file is the central configuration for the Jekyll site. Jekyll reads it once at build time — changes require a restart of `jekyll serve`.

**Site metadata:**
- `title` — Site name displayed in navigation and `<title>` tags. Any string.
- `description` — Site description used by jekyll-seo-tag for `<meta>` tags. Any string.
- `url` — Production URL (e.g. `"https://example.com"`). Used for absolute URLs in feeds and SEO tags. Must include protocol, no trailing slash.
- `google_analytics` — GA tracking ID (e.g. `UA-XXXXXXXX-X` or `G-XXXXXXXXXX`). Omit or leave placeholder to disable.

**Author:**
- `author.name` — Author name shown in post metadata. Any string.
- `author.url` — Author homepage URL. Any valid URL.
- `author.email` — Author email. Used by jekyll-feed for the Atom feed.

**Build settings:**
- `markdown` — Markdown processor. Values: `kramdown` (default/recommended), `commonmark`. This site uses `kramdown`.
- `highlighter` — Server-side syntax highlighter. Values: `rouge` (Jekyll default), `none` (disabled — this site uses `none` because highlight.js handles highlighting client-side).
- `kramdown.input` — Parser mode. Values: `GFM` (GitHub Flavored Markdown — enables fenced code blocks, tables, strikethrough), `kramdown` (kramdown's own syntax).
- `kramdown.footnote_nr` — Starting number for footnotes. Integer, default `1`.
- `kramdown.syntax_highlighter` — Kramdown-level highlighter. Values: `rouge`, `coderay`, `none`. Set to `none` here to prevent kramdown from tokenizing code blocks (highlight.js does it client-side instead).

**File inclusion/exclusion:**
- `include` — List of directories/files to process that Jekyll would normally ignore (directories starting with `_`). e.g. `[_pages]`.
- `exclude` — List of files/directories to skip during build. Accepts an array. Note: if specified twice in the file, YAML keeps only the last occurrence.

**Assets:**
- `sass.sass_dir` — Directory containing SCSS partials. Default `_sass`.
- `sass.style` — CSS output style. Values: `compressed` (minified), `expanded` (readable), `nested`, `compact`.

**Plugins:**
- `plugins` — List of Jekyll plugins to load. Available plugins for this site:
  - `jekyll-feed` — Generates an Atom feed at `/feed.xml`
  - `jekyll-paginate` — Paginates the post listing on the home page
  - `jekyll-seo-tag` — Injects SEO `<meta>` tags and Open Graph data
  - `jemoji` — (commented out) Renders GitHub-style emoji shortcodes

**Permalinks & pagination:**
- `permalink` — URL pattern for posts. Common values: `/:year-:month-:day/:title` (this site), `/blog/:title/`, `/:categories/:title/`, `pretty` (`/:categories/:year/:month/:day/:title/`), `date` (default: `/:categories/:year/:month/:day/:title.html`).
- `paginate` — Number of posts per page on the home listing. Positive integer.

**Disqus:**
- `disqus` — Disqus shortname for comment embedding. Any string matching your Disqus site ID. Posts must also set `comments: true` in front matter to enable.

## Folder Structure

```
tale/
├── _config.yml         # Central Jekyll config (read once at build/serve startup)
├── _layouts/           # HTML layout templates
│   ├── default.html    #   Root shell: <html>, <head>, scripts, includes
│   ├── home.html       #   Paginated post listing (extends default)
│   └── post.html       #   Single post with metadata (extends default)
├── _includes/          # HTML partials pulled into layouts via {% include %}
│   ├── head.html       #   <head> tag: meta, CSS, fonts, favicon links
│   ├── navigation.html #   Top nav bar with site title + page links
│   ├── footer.html     #   Copyright footer
│   ├── analytics.html  #   Google Analytics snippet
│   └── disqus_comments.html  # Disqus lazy-load embed
├── _posts/             # Blog posts (YYYY-MM-DD-slug.md)
├── _pages/             # Static pages (about, posts index, tags)
├── _sass/              # SCSS source files
│   ├── tale.scss       #   Master import file — controls import order
│   ├── tale/           #   Core theme partials:
│   │   ├── _variables.scss  # Colors, fonts, mixins
│   │   ├── _base.scss       # Global resets, typography, links
│   │   ├── _layout.scss     # Content width (max-width: 800px, width: 80%)
│   │   ├── _post.scss       # Post title, metadata, body paragraph styles
│   │   ├── _code.scss       # Inline code and pre/code base styles
│   │   ├── _syntax.scss     # Rouge token colors (legacy, now unused)
│   │   ├── _sidenote.scss   # Tufte-style sidenote positioning
│   │   ├── _footnotes.scss  # Footnote section styles
│   │   ├── _navigation.scss # Nav bar layout
│   │   ├── _pagination.scss # Prev/next and page number controls
│   │   ├── _catalogue.scss  # Home page post listing items
│   │   └── _tags.scss       # Tag cloud and tag post listing
│   ├── custom/
│   │   └── highlight.scss   # Code block styles (hljs table, line numbers, labels)
│   ├── table.scss           # Data table borders and padding
│   ├── popup.scss           # Hover popup styles (.popup, .popup-titlebar, annotated link indicator)
│   └── highlight-comments.scss  # Highlight-comment styles (.hc-annotation, .hc-tooltip, etc.)
├── assets/
│   ├── main.scss       # SCSS entry point (just imports tale.scss)
│   ├── js/             # JavaScript files
│   │   ├── highlight-code.js      # hljs init + line numbers + language labels
│   │   ├── sidenotes.js           # Footnote → sidenote conversion (jQuery)
│   │   ├── popup-lite.js          # Hover popups via data-popup-* attributes
│   │   ├── highlight-comments.js  # Reader text annotations with localStorage persistence
│   │   ├── anime.min.js           # Anime.js v4.3.6 UMD bundle
│   │   └── disqusLoader.js        # Lazy Disqus loader
│   └── fonts/          # Self-hosted webfonts (Merriweather, Source Sans/Code Pro)
├── index.html          # Homepage (uses home layout with pagination)
├── _site/              # Generated output (do not edit, rebuilt on every build)
├── Gemfile             # Ruby dependencies
├── flake.nix           # Nix flake for reproducible builds
└── tale.gemspec        # Gem packaging spec
```

## Content Conventions

- Posts use `YYYY-MM-DD-slug.md` naming in `_posts/`
- Front matter requires `layout: post` and `title`; optional fields: `author`, `tags`, `comments` (boolean for Disqus)
- Pages go in `_pages/` with a `permalink` in front matter
- Inline math: `$...$`, display math: `$$...$$`
- Footnotes are auto-converted to sidenotes on wide screens

## Workflow: Creating and Iterating on a Post

1. Create a file in `_posts/` named `YYYY-MM-DD-your-slug.md`
2. Add front matter at the top:
   ```yaml
   ---
   layout: post
   title: "Your Title"
   author: "Your Name"
   tags: [tag1, tag2]
   ---
   ```
3. Write content in Markdown (GFM dialect: fenced code blocks, tables, strikethrough all work)
4. Run `bundle exec jekyll serve` — the site rebuilds automatically when you save any content or SCSS file (but NOT `_config.yml` — that requires a restart)
5. View at http://127.0.0.1:4000/ — hard refresh (Cmd+Shift+R) if CSS/JS changes don't appear

## Customisation Guide

### Changing content width and margins

Edit `_sass/tale/_layout.scss`. The content column is controlled by:
```scss
main, footer, .nav-container {
  max-width: 800px;   /* absolute cap */
  width: 80%;          /* responsive width below cap */
}
```
Change `max-width` to widen/narrow the column. Change `width` to control how much of the viewport it fills on smaller screens.

### Changing typography and colors

Edit `_sass/tale/_variables.scss`. All fonts and colors are defined as SCSS variables with `!default`, so they can be overridden. Key variables:
- `$serif-primary` — body text font
- `$sans-serif` — headings, UI elements
- `$monospaced` — code blocks
- `$default-color` — primary text color
- `$blue` — link color
- `$grey-1` through `$grey-3` — background tints

### Changing post body styles (paragraph layout, spacing)

Edit `_sass/tale/_post.scss`. The `.post` class wraps all post content. For example, to make paragraphs left-aligned instead of justified, change `text-align: justify` to `text-align: left` in `.post p`.

### Creating custom layouts (e.g. split intro + table of contents)

1. Create a new layout file in `_layouts/`, e.g. `_layouts/post-with-toc.html`
2. Set `layout: default` in its front matter to inherit the shell
3. Use HTML/Liquid to structure the page however you like — for a two-column split:
   ```html
   ---
   layout: default
   ---
   <div class="post" style="display: flex; gap: 2rem;">
     <div style="flex: 1;">{{ content | split: '<!-- toc-break -->' | first }}</div>
     <div style="flex: 1;"><!-- TOC or sidebar content --></div>
   </div>
   ```
4. Use `layout: post-with-toc` in the post's front matter to apply it

### Adding custom CSS

Two approaches:
- **For theme-wide changes:** add or edit a partial in `_sass/` and import it in `_sass/tale.scss` (files imported later override earlier ones)
- **For per-page CSS:** add a `<style>` block in the post's markdown (kramdown passes raw HTML through)

### Adding custom JavaScript

Two approaches:
- **Site-wide:** add your `.js` file to `assets/js/` and add a `<script>` tag in `_layouts/default.html` (at the end of `<body>`, after the existing scripts)
- **Per-page:** add a `<script>` block directly in the post's markdown, or use front matter flags (like the existing `include_stl_viewer_js`) checked in `_includes/head.html` to conditionally load scripts:
  ```yaml
  # In _includes/head.html, add:
  {% if page.include_my_script -%}
    <script src="{{ "/assets/js/my-script.js" | relative_url }}"></script>
  {% endif -%}
  ```
  Then set `include_my_script: true` in any post's front matter to load it.

### Script loading order

Scripts are loaded in two places (both run before the page is interactive):
1. **`_includes/head.html`** — jQuery, sidenotes, and conditional scripts (STL viewer)
2. **`_layouts/default.html`** (end of body) — MathJax, Highlight.js + line numbers plugin, highlight-code.js, popup-lite.js, highlight-comments.js

New scripts that depend on jQuery should go after the jQuery `<script>` tag. New scripts that manipulate post content should go at the end of `default.html` or use `DOMContentLoaded`.

---

For deep-dive documentation on all custom features — Sidenotes, Hover Popup Annotations, Highlight Comments, Anime.js Animations, and TikZ Diagrams (including inline animated SVG internals) — see [DESIGN_DOC.md](DESIGN_DOC.md).

