# BibTeX Citations in Jekyll

Deep-dive documentation for the BibTeX/CSL citation feature implemented in
`_plugins/bibtex.rb`. For build commands, general file structure, and other
features see [DESIGN_DOC.md](DESIGN_DOC.md) and [CLAUDE.md](CLAUDE.md).

---

## Motivation

The Hakyll static-site generator has a clean story for academic citations: write
`[@key]` in Markdown, point Pandoc at a `.bib` and a `.csl` file, and Pandoc's
built-in citeproc processes everything at compile time. This Jekyll blog
replicates that workflow without switching away from Kramdown, using a custom
post-render plugin (`_plugins/bibtex.rb`) and the same underlying Ruby gems
(`bibtex-ruby`, `citeproc-ruby`, `csl-styles`) that power jekyll-scholar.

---

## Authoring

### Citation syntax

Use Pandoc-compatible citation keys anywhere in a post's body:

```markdown
A well-known result [@smith2020].
```

Multiple references in one bracket, separated by semicolons:

```markdown
Several authors agree [@smith2020; @jones2019; @chen2021].
```

Suppress the author name (produces just the year in author-date styles, or the
number in numeric styles) with a leading `-`:

```markdown
As shown earlier [-@smith2020].
```

Citations inside fenced code blocks and inline `code spans` are intentionally
ignored — the regex replacement skips every `<pre>` and `<code>` element in
the rendered HTML.

### Bibliography

Every post that contains at least one citation automatically gets a **References**
section appended before the closing `</div class="post">` wrapper. Posts without
citations are untouched. There is no Liquid tag to add, no front-matter flag to
set.

---

## Configuration

All settings live under `bibtex:` in `_config.yml`:

```yaml
bibtex:
  bibliography: _bib/bibliography.bib   # path relative to site root
  style:        apa                     # built-in CSL style name
  csl:          _bib/style.csl          # optional — custom .csl file path
                                        # takes precedence over style: if set
```

**`bibliography`** — path to the `.bib` file, relative to the Jekyll source
root. Defaults to `_bib/bibliography.bib`. The `_bib/` directory starts with an
underscore so Jekyll ignores it and never copies it to `_site/`.

**`style`** — any style name supported by the `csl-styles` gem. Common choices:

| Name | Format |
|---|---|
| `apa` | (Smith, 2020) — author-date |
| `ieee` | [1] — numeric |
| `chicago-author-date` | (Smith 2020) — author-date |
| `harvard-cite-them-right` | (Smith, 2020) — author-date |
| `vancouver` | 1. — numeric superscript |

Browse the full catalogue at [zotero.org/styles](https://www.zotero.org/styles).

**`csl`** — path to a custom `.csl` XML file (e.g. a journal's house style).
Download one from Zotero, place it in `_bib/`, and set this key. If set, `style:`
is ignored.

> **Note:** `_config.yml` is only read at startup. After changing `bibtex:`
> settings, restart `jekyll serve`.

---

## Bibliography file format

Standard BibTeX. LaTeX ligatures and special characters (`---`, `\'{e}`,
`\textit{…}`) are automatically decoded to Unicode by bibtex-ruby's `:latex`
filter, so you can write them either way.

```bibtex
@article{smith2020,
  author  = {Smith, Jane and Doe, John},
  title   = {An Example Article},
  journal = {Journal of Examples},
  year    = {2020},
  volume  = {42},
  pages   = {1--10},
  doi     = {10.0000/example.2020},
}

@book{jones2019,
  author    = {Jones, Alice},
  title     = {The Definitive Guide to Examples},
  publisher = {Example Press},
  year      = {2019},
}

@inproceedings{chen2021,
  author    = {Chen, Bob and Li, Carol},
  title     = {A Proceedings Paper},
  booktitle = {Proc. International Conference on Examples},
  year      = {2021},
  pages     = {200--215},
}
```

All standard BibTeX entry types are supported: `@article`, `@book`,
`@inproceedings`, `@incollection`, `@phdthesis`, `@techreport`, `@misc`, etc.
The CSL style controls which fields are displayed and how they are formatted.

---

## Implementation

### Files changed

| File | Change |
|---|---|
| `_plugins/bibtex.rb` | New plugin — full citation processing logic |
| `_bib/bibliography.bib` | New bibliography database (example entries) |
| `_layouts/post.html` | Added `<!-- bibtex-anchor -->` injection marker |
| `_sass/bibliography.scss` | New CSS for bibliography and citation spans |
| `_sass/tale.scss` | Added `@import 'bibliography'` |
| `Gemfile` | Added `bibtex-ruby`, `citeproc-ruby`, `csl-styles` |
| `_config.yml` | Added `bibtex:` config block |

### How the plugin works

The plugin registers two Jekyll hooks:

**`Jekyll::Hooks.register :site, :after_reset`** — loads the `.bib` file and
CSL style once per build cycle and stores them in module-level variables.
Parsing is done once per build, not once per post. `:after_reset` is used
rather than `:after_init` because Jekyll loads plugins inside `Site#reset`
(via `conscientious_require`) before triggering `:after_reset`, whereas
`:after_init` fires in `Site#initialize` before any plugins are loaded — so
hooks registered in plugins would never fire for that event.

**`Jekyll::Hooks.register :posts, :post_render`** — fires after Kramdown has
rendered the Markdown to HTML and the layout has been applied. At this point
`post.output` is the full page HTML. The plugin calls `BibtexPlugin.process`
and writes the result back to `post.output`.

Inside `process`:

1. **Collect keys.** The HTML is split on `<pre>` and `<code>` boundaries. Only
   non-code segments are scanned for the pattern `\[(-?@key[; @key2…])\]`. Keys
   are accumulated in a `Set`-like array (preserving insertion order, deduplicating).
   Posts with no citations return immediately.

2. **Build a CiteProc processor.** Only the cited entries are imported. For
   numeric styles this means numbering starts at 1 and matches citation order;
   for author-date styles the bibliography is CSL-sorted as usual.

3. **Replace citation markers.** The same code/non-code split is iterated again.
   In each non-code segment every `[@key]` cluster is replaced with
   `<span class="citation">…</span>` containing the formatted in-text text
   (e.g. `(Smith, 2020)` for APA or `[1]` for IEEE). Undefined keys produce a
   red `<span class="citation-error">` so they are visible during development.

4. **Render bibliography.** Each cited entry is formatted independently using a
   fresh single-entry CiteProc processor — this is slightly less efficient than
   rendering all at once, but it gives a reliable key→HTML mapping regardless of
   how the CSL style sorts entries. The entries are wrapped in
   `<div class="bibliography">` and injected in place of the
   `<!-- bibtex-anchor -->` HTML comment that was added to `post.html`.

### Why `<!-- bibtex-anchor -->` instead of string matching

Injecting before a bare `</div>` would be brittle — post content often contains
deeply nested divs. Searching for `</div>` with class heuristics is fragile.
A static HTML comment placed in `post.html` immediately before the closing tag
of `<div class="post">` gives the plugin an unambiguous, stable injection point
at zero runtime cost.

### Why not jekyll-scholar

`jekyll-scholar` provides the same BibTeX+CSL capability but uses Liquid tags:
`{% cite key %}` and `{% bibliography %}`. The goal here was to match the Hakyll
author workflow exactly — `[@key]` in plain Markdown, no template tags — which
requires a post-render HTML hook rather than Liquid tags.

---

## CSS reference

All styles are in `_sass/bibliography.scss`.

| Selector | Description |
|---|---|
| `.bibliography` | Wrapper div for the whole references section |
| `.bibliography h2` | "References" heading |
| `.bibliography-list` | Flex column containing individual entries |
| `.bibliography-entry` | One formatted reference; carries `id="ref-{key}"` |
| `.bibliography-entry .csl-entry` | Inner div added by citeproc-ruby; has hanging indent |
| `.citation` | Inline span wrapping the in-text citation marker |
| `.citation a` | Link from the in-text marker to `#references` |
| `.citation-error` | Red span shown for undefined/missing keys |

---

## Feature toggle

| Scope | Action |
|---|---|
| **Disable globally** | Delete or rename `_plugins/bibtex.rb`; remove `@import 'bibliography'` from `tale.scss` |
| **Disable per-post** | Simply don't write any `[@key]` markers — the plugin short-circuits immediately if no citations are found |
| **Change style** | Edit `bibtex.style` in `_config.yml` and restart `jekyll serve` |
| **Add a reference** | Add a BibTeX entry to `_bib/bibliography.bib` and restart `jekyll serve` |

---

## Troubleshooting

**"Bibliography not found"** warning in the build log — check that the path in
`bibtex.bibliography` matches the actual file location relative to the site root.

**Citation renders as red `[@key]`** — the key is not in the `.bib` file. Check
for typos; key matching is case-sensitive.

**In-text citation shows `[1]` instead of `(Smith, 2020)`** — the `render(:citation, …)`
call raised a `StandardError` and the numeric fallback fired. Check the Jekyll
build log for the error trace. The API used is
`processor.render(:citation, [{id: 'key'}, …])` (citeproc-ruby 2.1.x).

**Bibliography section not appearing** — verify that `<!-- bibtex-anchor -->` is
present in `_layouts/post.html` and that `jekyll serve` was restarted after the
layout change (layout changes are live-reloaded, but `_config.yml` changes are
not).

**Style changes not taking effect** — `_config.yml` is read once at startup.
Always restart `bundle exec jekyll serve` after changing the `bibtex:` block.
