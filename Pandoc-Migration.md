# Switching from Kramdown to Pandoc

This document analyses what changes when the blog's Markdown processor is switched from
**kramdown** (the current default) to **Pandoc**, and gives a step-by-step guide for
making the switch while keeping the rendered output visually identical.

---

## Why Switch?

| Concern | Kramdown | Pandoc |
|---|---|---|
| BibTeX / CSL citations | Custom plugin (`_plugins/bibtex.rb`) | Built-in `--citeproc` flag |
| Footnote/sidenote richness | Adequate | Same (different HTML shape) |
| Math | Passes `$…$` to MathJax | Converts to `\(…\)` spans for MathJax |
| Extended Markdown features | Good (GFM) | Excellent (Pandoc Markdown) |
| System dependency | Pure Ruby gem | Requires `pandoc` binary |
| Jekyll integration | Native | Via `jekyll-pandoc` gem |

The primary motivation to switch is usually to replace the custom `_plugins/bibtex.rb`
plugin with Pandoc's battle-tested `--citeproc` pipeline, or to gain access to Pandoc's
richer Markdown dialect (definition lists, bracketed spans, line blocks, etc.).

---

## What Stays the Same

- All post front matter (`layout`, `title`, `tags`, etc.)
- Liquid tags processed by Jekyll — `{% tikz %}`, `{% raw %}`, etc. — run *before* the
  Markdown converter and are unaffected
- MathJax rendering — `$…$` / `$$…$$` delimiters still work (Pandoc emits `\(…\)` /
  `\[…\]` spans, which the current MathJax 3 config already recognises via
  `inlineMath: [['$','$'], ['\\(','\\)']]`)
- Highlight.js syntax highlighting (code blocks produce identical `<pre><code
  class="language-X">` HTML)
- All custom CSS and JavaScript (popup-lite, highlight-comments, dark-mode-toggle,
  anime.js, tikz-loader)
- Citation syntax — `[@key]`, `[@key1; @key2]`, `[-@key]` — is already Pandoc's native
  format (no post edits needed)

---

## What Changes

### 1. Footnote / Sidenote HTML Structure

This is the **most impactful change**. `sidenotes.js` is tightly coupled to kramdown's
footnote HTML.

**Kramdown output:**
```html
<!-- in post body -->
<sup id="fnref:1"><a href="#fn:1">1</a></sup>

<!-- at end of page -->
<div class="footnotes">
  <ol>
    <li id="fn:1">
      <p>Content. <a href="#fnref:1" class="reversefootnote">↩</a></p>
    </li>
  </ol>
</div>
```

**Pandoc output:**
```html
<!-- in post body -->
<a href="#fn1" class="footnote-ref" id="fnref1" role="doc-noteref"><sup>1</sup></a>

<!-- at end of page -->
<section class="footnotes footnotes-end-of-document" role="doc-endnotes">
  <hr />
  <ol>
    <li id="fn1" role="doc-endnote">
      <p>Content.<a href="#fnref1" class="footnote-back" role="doc-backlink">↩︎</a></p>
    </li>
  </ol>
</section>
```

**Differences that break `sidenotes.js`:**

| Detail | Kramdown | Pandoc |
|---|---|---|
| Inline ref element | `<sup><a href="#fn:1">` | `<a class="footnote-ref" href="#fn1"><sup>` |
| ID separator | Colon — `fn:1`, `fnref:1` | No colon — `fn1`, `fnref1` |
| Footnote container | `<div class="footnotes">` | `<section class="footnotes">` |
| Back-link class | `reversefootnote` | `footnote-back` |

`sidenotes.js` uses `a[href^='#fn:']` to detect footnote refs — this will match nothing
under Pandoc. It must be changed to `a.footnote-ref` (or `a[href^='#fn']` to handle both
formats during transition). Similarly, the back-link stripping code that removes
`.reversefootnote` elements must also strip `.footnote-back`.

### 2. BibTeX / Citation Plugin

`_plugins/bibtex.rb` is entirely replaced by Pandoc's `--citeproc`. The `[@key]` syntax
in posts is unchanged. The bibliography section is emitted by Pandoc as a `<div id="refs">`
at the end of the document, rather than being injected at `<!-- bibtex-anchor -->`.

The `bibliography.scss` styles target `.bibliography`; they need one extra rule:
`#refs` with the same styles, or the class name on the wrapping div needs adjusting
(see configuration section).

### 3. Inline Attribute Lists (IAL)

Kramdown supports `{: .class #id}` after elements:
```markdown
Some paragraph.
{: .important}
```

Pandoc uses the same curly-brace syntax but **without the leading colon**:
```markdown
Some paragraph.
{.important}
```

Audit all posts for `{:` usage and remove the colon. This is the only syntax change
needed in post content.

### 4. Bibliography Location

With kramdown + `bibtex.rb`, the bibliography is injected at `<!-- bibtex-anchor -->` in
`post.html`, which places it before the footnotes. With Pandoc `--citeproc`, the
bibliography (`<div id="refs">`) is appended after the last paragraph of the post but
before the footnote section. If the exact placement matters, a Pandoc Lua filter can
reposition it.

### 5. Nix Flake

The `pandoc` binary must be available in the build environment. It is not in the current
`flake.nix`.

---

## Step-by-Step Migration

### Step 1 — Install Pandoc

**macOS (Homebrew):** `brew install pandoc`

**Nix flake** — add to `texlivePkgs` or as a separate package in `flake.nix`:
```nix
buildInputs = [ ruby pkgs.pandoc ] ++ texliveEnv.packages;
```

### Step 2 — Update Gemfile

Remove the three BibTeX gems, add `jekyll-pandoc`:

```ruby
# Remove:
gem "bibtex-ruby"
gem "citeproc-ruby"
gem "csl-styles"

# Add:
gem "jekyll-pandoc"
```

Run `bundle install` (or `BUNDLE_PATH=vendor/bundle bundle install` under Nix) to
regenerate `Gemfile.lock`.

### Step 3 — Update `_config.yml`

Replace the kramdown block with a Pandoc block:

```yaml
# Remove:
markdown:    kramdown
highlighter: none
kramdown:
  footnote_nr: 1
  input: GFM
  syntax_highlighter: none

bibtex:
  bibliography: _bib/bibliography.bib
  style:        apa

# Add:
markdown: Pandoc
pandoc:
  extensions:
    - "--from=markdown+raw_html+auto_identifiers+fenced_code_blocks"
    - "--no-highlight"
    - "--mathjax"
    - "--citeproc"
    - "--bibliography=_bib/bibliography.bib"
    - "--csl=apa"
```

`--no-highlight` tells Pandoc not to do server-side syntax highlighting (highlight.js
handles this client-side). `--csl=apa` uses Pandoc's built-in APA style; alternatively
point to a downloaded CSL file: `--csl=_bib/apa.csl`.

Add `jekyll-pandoc` to the plugins list:
```yaml
plugins:
  - jekyll-feed
  - jekyll-paginate
  - jekyll-seo-tag
  - jekyll-pandoc
```

### Step 4 — Delete `_plugins/bibtex.rb`

Pandoc's `--citeproc` replaces it entirely. Delete the file.

```bash
rm _plugins/bibtex.rb
```

### Step 5 — Update `_layouts/post.html`

Remove the `<!-- bibtex-anchor -->` marker (it's no longer used):

```html
<!-- Remove this line: -->
<!-- bibtex-anchor -->
```

### Step 6 — Update `assets/js/sidenotes.js`

Three targeted changes are needed to match Pandoc's footnote HTML:

**a) Reference detection** — change the inline-ref selector:
```javascript
// From (kramdown):
document.querySelectorAll('a[href^="#fn:"]')

// To (Pandoc):
document.querySelectorAll('a.footnote-ref')
```

**b) ID lookup** — kramdown IDs include a colon (`fn:1`); Pandoc omits it (`fn1`).
Any code that builds an ID from the href should strip the colon:
```javascript
// From:
var id = ref.getAttribute('href');       // "#fn:1"
var li = document.querySelector(id);    // finds <li id="fn:1">

// To:
var id = ref.getAttribute('href');       // "#fn1" — no colon, just works
var li = document.querySelector(id);
```
If the existing code uses a regex like `href.replace('#fn:', '#fn')`, remove that
transform; it's no longer needed since Pandoc omits the colon from the start.

**c) Back-link stripping** — Pandoc's back-link class is `footnote-back`, not
`reversefootnote`. The current code already strips `.footnote-backref` (for CommonMark);
add `.footnote-back` to the same logic:
```javascript
// Existing:
clone.querySelectorAll('.reversefootnote, .footnote-backref').forEach(el => el.remove());

// Change to:
clone.querySelectorAll('.reversefootnote, .footnote-backref, .footnote-back').forEach(el => el.remove());
```

### Step 7 — Update `_sass/bibliography.scss`

Pandoc wraps the bibliography in `<div id="refs">` rather than `<div
class="bibliography">`. Either rename the existing class rule or add an ID rule:

```scss
.bibliography,
#refs {
  // existing styles
}
```

### Step 8 — Update `_sass/tale/_footnotes.scss`

The footnote container changes from `<div class="footnotes">` to `<section
class="footnotes">`. The `.footnotes` class is the same, so **no change is needed** —
the rule `div.footnotes` (if it exists) should be broadened to just `.footnotes`, which
it already is in the current file.

### Step 9 — Audit Posts for IAL Syntax

Search all posts for kramdown IAL syntax and remove the leading colon:

```bash
grep -r '{:' _posts/
```

For each match, change `{: .class}` → `{.class}`, `{: #id}` → `{#id}`, etc.

### Step 10 — Test

```bash
bundle exec jekyll serve
```

Check:
1. **Posts with citations** — bibliography appears at end of post
2. **Posts with footnotes** — sidenotes appear on desktop; fallback footnote list on mobile
3. **Posts with math** — inline and display math renders
4. **Code blocks** — highlight.js colours and line numbers apply
5. **Posts with TikZ** — SVGs still appear
6. **Tags / home / about pages** — no visual regressions

---

## Risk Summary

| Feature | Risk | Notes |
|---|---|---|
| Sidenotes | **High** | Requires `sidenotes.js` edits (Step 6) |
| BibTeX citations | **Low** | Same `[@key]` syntax; different output div |
| Math | **None** | MathJax 3 config already handles Pandoc's output |
| Code highlighting | **None** | Pandoc `--no-highlight` keeps hljs in control |
| TikZ | **None** | Liquid plugin runs before the Markdown converter |
| Tables | **None** | Pipe-table syntax is the same |
| IAL syntax | **Low** | Manual find-and-replace in posts |
| Dark mode toggle | **None** | Pure JS/CSS, converter-agnostic |

---

## Rollback

The switch is reversible. To roll back, restore `Gemfile`, `_config.yml`,
`_plugins/bibtex.rb`, the `<!-- bibtex-anchor -->` marker in `post.html`, and
the original `sidenotes.js` selectors.
