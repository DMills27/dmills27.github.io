# DESIGN_DOC.md

Deep-dive documentation for every custom feature in this Jekyll blog. This file covers
internal design decisions, implementation details, authoring patterns, and CSS/JS class
references. For build commands, file structure, and configuration see [CLAUDE.md](CLAUDE.md).

---

## Feature Toggles

Quick reference for enabling and disabling each feature. All script tags are in
`_layouts/default.html` (end of `</html>`) except sidenotes, which is also in
`_includes/head.html` line 12.

### Sidenotes

**Loaded in:** `_includes/head.html` (line 12) **and** `_layouts/default.html` (line 37) — both must be changed together.

| Scope | Action |
|---|---|
| **Disable globally** | Remove `<script src="…/sidenotes.js">` from both files |
| **Disable per-post** | Add `{% if page.sidenotes != false %}…{% endif %}` guards around both script tags, then set `sidenotes: false` in a post's front matter |
| **Enable globally** | Script tags present (default) |

When sidenotes are disabled, kramdown's standard `.footnotes` section appears at the bottom of the post as normal.

### Hover Popup Annotations

**Loaded in:** `_layouts/default.html` (line 48).

| Scope | Action |
|---|---|
| **Disable globally** | Remove `<script src="…/popup-lite.js">` from `default.html` |
| **Disable per-post** | Not needed — the script only activates on links that have a `data-popup-title` attribute. A post with no such links pays no cost |
| **Enable for a link** | Add `data-popup-title="…"` (and optional `data-popup-*` attrs) to any Markdown link via kramdown's `{: }` attribute syntax |

### Highlight Comments

**Loaded in:** `_layouts/default.html` (line 49).

| Scope | Action |
|---|---|
| **Disable globally** | Remove `<script src="…/highlight-comments.js">` from `default.html` |
| **Disable per-post** | Wrap the script tag in a front-matter guard: `{% unless page.disable_highlight_comments %}…{% endunless %}`, then set `disable_highlight_comments: true` in the post's front matter |
| **Enable globally** | Script tag present (default) — the script is already a no-op on pages without a `.post` element (home, tags, archive) |

Disabling does not remove annotations that readers have already stored in `localStorage`; those persist until the reader clears browser storage.

### Anime.js Animations

**Loaded in:** each post individually (opt-in, not global).

| Scope | Action |
|---|---|
| **Enable for a post** | Add `<script src="/assets/js/anime.min.js"></script>` anywhere in the post's markdown before the first animation `<script>` block |
| **Disable for a post** | Remove or don't include that `<script src>` tag — no other change needed |
| **Disable globally** | Nothing to remove — the bundle is never loaded unless a post author explicitly includes it |

### TikZ Diagrams

Two independent components can be toggled separately: the Ruby plugin (compile-time) and the JS loader (runtime inline injection).

**Plugin loaded from:** `_plugins/tikz.rb` (Jekyll loads all `_plugins/*.rb` automatically).
**Loader loaded in:** `_layouts/default.html` (line 50).

| Scope | Action |
|---|---|
| **Disable plugin globally** | Delete or rename `_plugins/tikz.rb`. Jekyll will no longer recognise `{% tikz %}` tags; any post using them will fail to build with a Liquid syntax error |
| **Disable per-post** | Simply don't use `{% tikz %}` tags. The plugin only runs when a tag is present; no cost otherwise |
| **Disable inline loader only** | Remove `<script src="…/tikz-loader.js">` from `default.html`. Standard `<img>` diagrams still work; `{% tikz name inline %}` divs are left empty (no SVG injected, no error thrown) |
| **Enable** | Both `_plugins/tikz.rb` and `tikz-loader.js` present (default) |

> **Note:** removing the plugin does not delete already-compiled SVGs from `assets/tikz/`. Those are static files and continue to be served until manually deleted.

---

## Sidenotes

Footnotes (written with standard kramdown `[^n]` / `[^n]:` syntax) are displayed in two modes depending on viewport width:

- **Desktop (≥ 600 px)** — footnotes are rendered as absolutely-positioned sidenotes to the right of the post column. The `.footnotes` section at the bottom is hidden.
- **Mobile (< 600 px)** — sidenotes are absent; the `.footnotes` section is shown as normal.

The breakpoint (600 px) matches the theme's mobile breakpoint defined in `_sass/tale/_variables.scss`.

### Jekyll integration

`sidenotes.js` is loaded synchronously in `_includes/head.html` (immediately after jQuery, which it depends on). All its work runs inside `$(window).on('load', …)`, which fires after `DOMContentLoaded` and after all end-of-body scripts in `default.html` have executed — including `highlight-code.js`. This ordering means that when sidenotes clone footnote content, syntax highlighting is already applied to any code blocks inside the footnotes.

### Mode switching

Mode is determined by `window.matchMedia('(min-width: 600px)')`. A `change` listener on that `MediaQueryList` fires whenever the viewport crosses the breakpoint, calling either `buildSidenotes()` or `destroySidenotes()`. This is more reliable and efficient than a polling `resize` listener.

**`buildSidenotes($footnotes, fnli)`**
1. Forces `.footnotes` to `display: block` for measurement (it may have been hidden by a prior desktop session).
2. For each `<sup>` element with a `#fn:` href, calls `showSidenote()` and pushes the returned record into `records`.
3. Sets `.footnotes` to `display: none`.

**`destroySidenotes($footnotes)`**
1. Iterates `records`, calling `clearInterval(rec.intervalId)` and `rec.$div.remove()` for each.
2. Clears the `records` array.
3. Sets `.footnotes` to `display: ''` (restores default block display).

Each sidenote record is `{ $div, intervalId }`. Storing the interval ID is essential for proper teardown — without it, the `setInterval(sizeit, 3000)` positioning loop would continue running against a removed element.

### Content cloning

`showSidenote()` uses `cloneNode(true)` (deep DOM clone) rather than the previous `innerHTML` round-trip. This preserves:

- **Highlighted code blocks** — all `<span class="hljs-*">` tokens and the line-number `<table class="hljs-ln">` structure are copied exactly.
- **Images** — `<img>` elements with all attributes and computed state.
- **Arbitrary HTML** — `<strong>`, `<em>`, `<a>`, `<ul>`, etc.

After cloning the `<li>`, `extractContent()` removes `.reversefootnote` / `.footnote-backref` links and returns a `DocumentFragment` of the remaining children.

### Ordinal header placement

The "1. " label is inserted as a `<span class="sidenote-header">` *inside* the first block-level element of the cloned content (`p`, `h2`–`h4`, `pre`, `ul`, `ol`, `blockquote`). This makes the number flow inline with the opening text at normal block display, removing the need for the old `p { display: inline }` CSS override which prevented code blocks and images from rendering as blocks.

### Script re-execution (`rerunScripts`)

Cloned `<script>` nodes are inert by the HTML spec — the browser does not re-execute them. `rerunScripts(container)` replaces each cloned `<script>` with a freshly created element (copying all attributes and text content) so the browser executes it. This allows footnotes to embed self-contained anime.js animations.

**ID conflict caveat for anime.js.** If an animation script uses `document.getElementById('my-id')`, it resolves to the *first* element with that ID in the document — the one in the post body, not the sidenote copy. Two elements with the same ID exist simultaneously, and the animation targets the wrong one.

The workaround is to scope the lookup to the last matching element rather than the first:

```js
// Instead of: document.getElementById('demo-wave')
var containers = document.querySelectorAll('.my-anim');
var el = containers[containers.length - 1]; // targets the most recently inserted copy
```

Animations that build their DOM entirely via `document.createElement` and capture the container reference in a closure are unaffected by this issue.

### Writing rich footnotes

**Code block in a footnote** (kramdown continuation syntax — 4-space or 1-tab indent):

```markdown
Here is the algorithm.[^1]

[^1]: This snippet illustrates it:

    ```python
    def hello():
        print("hello")
    ```
```

**Image in a footnote:**

```markdown
See the diagram.[^2]

[^2]: The layout:

    ![diagram](/assets/img/diagram.png)
```

**Anime.js animation in a footnote** (use class, not id, for the container):

```markdown
Watch this.[^3]

[^3]: A bouncing dot:

    <div class="fn-dot-demo" style="padding:1rem;"></div>

    <script>
    (function () {
      var els = document.querySelectorAll('.fn-dot-demo');
      var el = els[els.length - 1]; // target the sidenote copy
      var dot = document.createElement('span');
      dot.style.cssText = 'display:inline-block;width:12px;height:12px;border-radius:50%;background:#5ae;';
      el.appendChild(dot);
      anime.animate(dot, { y: -16, loop: true, alternate: true, duration: 500 });
    }());
    </script>
```

Note: `anime` must be loaded before the footnote's `<script>` runs. If the post already has `<script src="/assets/js/anime.min.js"></script>` in the body, that is sufficient — the bundle loads once and sets `window.anime`.

### CSS (`_sass/tale/_sidenote.scss`)

| Selector | Purpose |
|---|---|
| `.sidenote` | Absolute-positioned card; `font-size: 0.8em`; left border |
| `.sidenote-header` | Bold ordinal ("1. ") prepended to first block |
| `.sidenote-hover` | Orange highlight colour applied on `<sup>` hover |
| `.sidenote img` | `max-width: 100%; height: auto` — prevents image overflow |
| `.sidenote pre` | `max-width: 100%; overflow-x: auto` — scrollable wide code |
| `.sidenote code` | `white-space: pre-wrap` — wraps within the column |
| `.sidenote pre code` | `white-space: pre` — overrides wrap inside `<pre>` blocks |
| `.reversefootnote`, `.footnote-backref` | `display: none` — back-arrows hidden in sidenotes |

### Files

| File | Purpose |
|---|---|
| `assets/js/sidenotes.js` | All sidenote logic: mode switching, cloning, script re-execution, positioning |
| `_sass/tale/_sidenote.scss` | Sidenote CSS including rich-content overrides |

---

## Hover Popup Annotations

Popup annotations display a rich tooltip when the reader hovers a link. The system supports multiple concurrent popups, dragging, pinning, and keyboard dismissal.

### Authoring a popup link

Use Kramdown's inline attribute syntax `{: attr="value"}` immediately after the Markdown link:

```markdown
[Link text](https://url.com){:
  data-popup-title="Title shown in bar and body"
  data-popup-author="Author or source"
  data-popup-date="2024"
  data-popup-tags="tag1,tag2,tag3"
  data-popup-abstract="Body text. Plain text or HTML both work."
  data-popup-image="/path/to/image.jpg"
}
```

**Only `data-popup-title` is required** — its presence is what `popup-lite.js` uses to attach hover behaviour (`a[data-popup-title]`). All other attributes are optional; absent sections are simply omitted from the rendered popup.

| Attribute | Rendered as | Notes |
|---|---|---|
| `data-popup-title` | Title bar label + bold heading | Required |
| `data-popup-author` | Italic author span in meta line | Optional |
| `data-popup-date` | Date span in meta line | Optional |
| `data-popup-tags` | Tag pills linking to `/tags/<tag>` | Comma-separated |
| `data-popup-abstract` | Blockquote body | Plain text or HTML |
| `data-popup-image` | Preview image below abstract | URL |

### Popup behaviour

- **Trigger delay** — 750 ms hover before the popup appears (prevents accidental flashes).
- **Multiple popups** — hovering a second link opens a second popup without closing the first.
- **Drag** — grab the dotted title bar to reposition.
- **Pin** — click the 📌 button to keep a popup open after the cursor leaves.
- **Close** — click ✕, click outside all popups, or press Escape.
- **Click-to-show** — first click on a link shows the popup; second click navigates.

### Files

| File | Purpose |
|---|---|
| `assets/js/popup-lite.js` | All popup logic (vanilla JS, no dependencies) |
| `_sass/popup.scss` | All popup CSS; uses theme SCSS variables |

---

## Highlight Comments

Readers can select any text within a post body to open a comment tooltip. Annotations that receive at least one comment are saved to `localStorage` and restored on the next page load. No post markup is required.

### Jekyll integration

`highlight-comments.js` is loaded unconditionally from `_layouts/default.html` (end of `<body>`). Its `init()` function calls `document.querySelector('.post')` and silently returns if the element is absent, so it is a no-op on home, tag, and archive pages. CSS lives in `_sass/highlight-comments.scss`, imported at the end of `_sass/tale.scss` after all theme partials so it can freely override base styles.

### Selection lifecycle

When a reader makes a text selection and releases the mouse button, the following sequence runs synchronously:

1. **`mouseup` fires** — `window.getSelection()` is read. If the selection is collapsed (a bare click with no drag), the handler returns immediately.
2. **`isRangeWrapSafe(range)` validates** — the range is rejected if any of the following are true (see validation rules below). An invalid range clears the selection and returns.
3. **Lock acquired** — `isProcessing = true` is set synchronously before any DOM work, preventing re-entrant calls from a second rapid `mouseup`.
4. **Pre-validation** — `range.cloneContents().textContent.trim()` checks that the selection contains non-whitespace text *before* any DOM mutation. If empty, an error is thrown and the lock is released.
5. **Serialise** — `serializeRange(range.cloneRange())` records the position as a `blockIdx` + `textStart` pair (see Serialisation below) *before* the DOM is mutated.
6. **Wrap** — `wrapRange(range.cloneRange(), id)` calls `range.extractContents()` to lift the selected nodes into a `DocumentFragment`, appends a `<span class="hc-bubble">` sibling, wraps both in `<span class="hc-annotation">`, and reinserts with `range.insertNode()`. This preserves all inline formatting (`<em>`, `<strong>`, `<a>`, etc.) because `extractContents` moves the actual DOM nodes, not a text-only copy.
7. **Open tooltip** — `openTooltip(wrapper)` positions and fades in the comment UI.
8. **`suppressNextClick = true`** — set immediately after the tooltip opens to absorb the `click` event that browsers always fire after a `mouseup`. Without this flag the click handler would fire, see that its target (recorded at mousedown time, before the DOM mutation) is not inside `.hc-annotation`, and immediately call `closeTooltip()` — making the feature appear broken.
9. **Lock released** — `isProcessing = false` in the `finally` block.

### Range validation (`isRangeWrapSafe`)

All conditions must pass for a selection to become an annotation:

| Check | Why |
|---|---|
| Range is not collapsed | A bare click with no drag yields a zero-length range |
| `document.querySelector('.post')` exists | Guard for non-post pages |
| `post.contains(commonAncestorElement)` | Selection must be inside the post body |
| No ancestor in `EXCLUDED` list | Prevents annotating the post header, code blocks, existing highlights, or the open tooltip |
| `range.toString().trim()` is non-empty | Rejects whitespace-only selections |
| No `.hc-annotation` ancestor in live DOM | Catches selections fully inside an existing highlight — `cloneContents()` alone cannot detect this because the wrapping span lies outside the cloned fragment |
| `cloneContents()` fragment contains no `.hc-annotation` or block-level elements | Catches partial overlaps with existing annotations and cross-paragraph selections |

### Serialisation and restore

Because DOM positions (node references, offsets) are ephemeral, annotations are stored as **text-content character offsets** within a stable block element, computed by a `TreeWalker` over `TEXT_NODE`s.

**`serializeRange(range)` algorithm:**
1. Walk up from `range.startContainer` until a block element that appears in `getAnnotatableBlocks()` (`p, li, h2, h3, h4, blockquote` inside `.post`, excluding header/code areas) is found. Record its index as `blockIdx`.
2. Create a `TreeWalker` over that block's text nodes. Accumulate `charCount` per node until `walker.currentNode === range.startContainer`. At that point add `range.startOffset`. The total is `textStart`.
3. Store `{ blockIdx, textStart, textLength: range.toString().length, selectedText: range.toString() }`.

**`deserializeRange(record)` algorithm:**
1. Retrieve `blocks[blockIdx]`. If the block no longer exists, return `null`.
2. Walk its text nodes again, accumulating `charCount`. The start node is the first node where `charCount + nodeLength > textStart`; `startOff = textStart - charCount`. The end node is the first node where `charCount + nodeLength >= textStart + textLength`; `endOff = textStart + textLength - charCount`.
3. Construct a `Range`, then verify `range.toString() === selectedText`. If the check fails (post content was edited), return `null` — the annotation is silently skipped.

Because the walker sees all text nodes regardless of intermediate annotation spans, offsets remain correct even when earlier annotations in the same block have already been restored and added wrapper elements.

### Tooltip lifecycle

- **Open** — `openTooltip(annotationEl)` first calls `closeTooltip()` to dismiss any existing tooltip. The new tooltip is positioned with `position: fixed` at `rect.bottom + 6` / `rect.left` (no scroll offset — fixed elements are already in viewport coordinates). After appending, a `requestAnimationFrame` measures the tooltip's rendered dimensions and clamps it: if the right edge overflows it shifts left; if the bottom edge overflows it flips above the annotation.
- **Scroll / resize** — passive `scroll` and `resize` listeners call `repositionTooltip()`, which repeats the `getBoundingClientRect` + clamp logic on every frame.
- **Close** — `closeTooltip()` checks whether the annotation has zero comments and `committed === false`. If so, `unwrapAnnotation()` moves all non-bubble child nodes back to the parent in a `DocumentFragment` (preserving inline formatting) and removes the wrapper. If comments exist the highlight remains. The tooltip element is always removed.
- **`committed` flag** — set to `true` the first time a comment is posted. This prevents `closeTooltip()` from removing a highlight the user returns to later (even if they add no new comments on that visit).

### CSS class reference

| Class | Element | Purpose |
|---|---|---|
| `.hc-annotation` | `<span>` wrapping selected text | Blue tinted background + dashed underline; `position: relative` to anchor the bubble |
| `.hc-bubble` | `<span>` inside `.hc-annotation` | Comment count or 💬 icon; `opacity: 0`, revealed on `.hc-annotation:hover` |
| `.hc-tooltip` | `<div>` appended to `<body>` | `position: fixed` card; appears below the annotation |
| `.hc-comment` | `<div>` per comment | Flex row containing avatar + text |
| `.hc-avatar` | `<div>` | Circular initial badge; `background` set via `style.backgroundColor` (not innerHTML) |
| `.hc-comment-author` | `<div>` | Bold author name; set with `textContent` |
| `.hc-comment-text` | `<div>` | Comment body; set with `textContent` |
| `.hc-input` | `<textarea>` | New comment input; focus ring uses `$blue` |
| `.hc-post-btn` | `<button>` | Submit button; disabled until input is non-empty; `$blue` when enabled |

All colors reference SCSS variables from `_variables.scss` (`$blue`, `$grey-1`, `$grey-2`, `$grey-3`, `$white`, `$default-color`, `$default-shade`, `$shadow-color`, `$sans-serif`).

### Persistence

Records are saved under `localStorage` key `hc:<window.location.pathname>` as a JSON array. Only annotations with `comments.length > 0` are written. Each record:

```json
{
  "id": "uuid",
  "blockIdx": 2,
  "textStart": 47,
  "textLength": 12,
  "selectedText": "spacing effect",
  "comments": [
    { "author": "You", "color": "#5ae", "text": "Great point.", "timestamp": 1709500000000 }
  ]
}
```

On page load, `restoreAnnotations()` iterates the stored records, calls `deserializeRange`, validates with `isRangeWrapSafe`, then calls `wrapRange` to re-highlight. The `selectedText` sanity check ensures that if a post is edited and the text no longer exists verbatim, the stale annotation is dropped rather than mis-highlighting something else.

### Files

| File | Purpose |
|---|---|
| `assets/js/highlight-comments.js` | All logic: selection, validation, serialisation, tooltip, localStorage |
| `_sass/highlight-comments.scss` | All CSS: `.hc-annotation`, `.hc-bubble`, `.hc-tooltip`, comment rows, input |

---

## Anime.js Animations

Anime.js v4.3.6 is integrated as a static asset served from `assets/js/anime.min.js`. It is opt-in per post — not loaded globally — using a plain `<script>` tag in the post's markdown.

### Jekyll integration

**Why UMD, not ESM.** Anime.js ships two bundles: an ES-module build (`anime.esm.min.js`) and a UMD build (`anime.umd.min.js`). The UMD build was chosen because each `<script>` block in a post's markdown is a separate, classic-mode script that shares the same global scope. The UMD bundle assigns `window.anime = { animate, createTimeline, stagger, svg, … }`, so every subsequent `<script>` block on the same page can destructure from `anime` without any import statement. The ESM build would require `type="module"`, which creates an isolated module scope per block — the `anime` binding from a `<script type="module">` loader block would be invisible to other `<script type="module">` blocks on the page unless they each re-imported it.

**File location.** The original source lives in `anime/dist/bundles/anime.umd.min.js` (inside the `anime/` project folder in the repository root). A copy was placed at `assets/js/anime.min.js` so Jekyll serves it as a static asset at `/assets/js/anime.min.js`.

**Excluding the source folder.** The `anime/` folder contains `node_modules` and other non-web files. Jekyll would attempt to copy everything it finds that is not excluded, so `anime` was added to the `exclude` list in `_config.yml`:

```yaml
exclude: [ Gemfile, Gemfile.lock, tale.gemspec, anime, "untitled folder" ]
```

**Important:** `_config.yml` had two `exclude:` keys. YAML keeps only the last occurrence when the same key appears twice, so the addition was made to the *second* (last) `exclude` block. If a first block is visible in the file, it is silently ignored by Jekyll.

**Script loading.** The bundle is loaded synchronously (no `defer` or `async`) via a tag placed directly in the post markdown:

```html
<script src="/assets/js/anime.min.js"></script>
```

Kramdown passes raw HTML elements through to the output unchanged, so this tag appears verbatim in the rendered HTML. Because it is synchronous and inline, the browser fetches and executes the script before parsing any subsequent `<script>` block in the same post, guaranteeing that `window.anime` is defined by the time the animation code runs. No `DOMContentLoaded` listener or deferred execution is needed.

### Writing animation blocks

The recommended pattern is one `<script src="…">` at the top of the section, followed by individual `<script>` blocks per demo, each wrapped in an IIFE:

```html
<script src="/assets/js/anime.min.js"></script>

<div id="my-demo" style="display:flex; gap:12px; padding:2rem;">
  <!-- elements built in JS or authored in HTML -->
</div>

<script>
(function () {
  const { animate, stagger } = anime;
  animate('#my-demo span', {
    y: [-30, 0],
    ease: 'out(3)',
    duration: 600,
    delay: stagger(80),
  });
}());
</script>
```

**Why IIFEs.** Each animation demo may declare helper variables (`container`, `cells`, `colors`, etc.). Without an enclosing function scope those names become global and can collide between demos on the same page. An IIFE creates a private scope at zero cost.

### Animation property syntax

**From/to arrays.** Any animatable property accepts a `[from, to]` tuple instead of a bare target value. Anime.js jumps the element to `from` at the start of the animation and interpolates to `to`:

```js
scale: [0, 1]     // jump to 0, animate to 1
opacity: [0, 1]
y: [-30, 0]       // jump 30 px above, fall into place
```

A bare scalar (`scale: 0`) animates from the element's *current* value to `0` — useful in a second `.add()` call where the previous step already established the starting state.

**Easing strings.** Anime.js v4 uses a functional notation for easing curves:

| String | Meaning |
|---|---|
| `'out(3)'` | Ease-out with power 3 (strong deceleration) |
| `'in(2)'` | Ease-in with power 2 (moderate acceleration) |
| `'inOut(3)'` | Ease-in-out, symmetric, power 3 (smooth start and stop) |
| `'linear'` | No easing |
| `'spring(mass, stiffness, damping, velocity)'` | Physics-based spring |

The parenthesised number is the polynomial exponent — higher values produce a more dramatic ramp.

### `stagger` options

`stagger(baseDelay, opts)` returns a function that Anime.js calls with each element's index to produce a per-element `delay` value:

| Option | Type | Effect |
|---|---|---|
| `start` | number | Offset added to all computed delays (shifts the whole wave in time) |
| `from` | `'first'` / `'last'` / `'center'` / index | Reference point for delay calculation — `'center'` makes the middle element fire first, outer elements last |
| `grid` | `[cols, rows]` | Switches from linear (1-D index) to 2-D Manhattan / Euclidean distance from the `from` point; each element's delay is proportional to its grid distance |
| `axis` | `'x'` / `'y'` | When used with `grid`, compute distance along one axis only |
| `easing` | string | Apply an easing curve to the stagger spread itself (not the animation) |

**Example — grid ripple:** `stagger(55, { grid: [6, 6], from: 'center' })` assigns delays proportional to each cell's Euclidean distance from the centre of a 6×6 grid. The centre cells animate first; corner cells animate last, producing a ripple effect.

### Timeline API

`createTimeline(opts)` returns a timeline object. Animations are chained with `.add()` and the timeline is started with `.init()`:

```js
createTimeline({
  loop: true,        // repeat indefinitely
  loopDelay: 600,    // ms to pause between loop iterations (default: 0)
  defaults: { ease: 'inOut(3)', duration: 1000 },  // applied to every .add() unless overridden
})
.add(targets, props, timeOffset)   // timeOffset: ms from timeline start, or stagger fn
.add(targets, props, timeOffset)
.init();                            // required — starts playback
```

**`.add()` signature:**
- `targets` — any valid CSS selector string, DOM element, `NodeList`, or the return value of `svg.createDrawable()`.
- `props` — animation properties object; same syntax as `animate()`.
- `timeOffset` *(optional)* — absolute ms position within the timeline, or the return value of `stagger()` to stagger each element's start across the timeline.

**`.init()` is required.** Without it the timeline is constructed but never starts. This design lets you chain all `.add()` calls before any animation frame fires.

**`loopDelay`.** When `loop: true`, each complete pass through the timeline pauses for `loopDelay` ms before restarting from the beginning. This gives the viewer a moment to register the completed state before the cycle repeats.

### SVG `draw` property

`svg.createDrawable(selector)` wraps matched SVG stroke elements and exposes a synthetic `draw` property that maps to `stroke-dashoffset` and `stroke-dasharray` automatically. The value is a `"start end"` string where both `start` and `end` are fractions of the total path length (0 = path beginning, 1 = path end):

| `draw` value | Visual effect |
|---|---|
| `'0 0'` | Stroke fully hidden (zero-length visible segment) |
| `'0 1'` | Stroke fully drawn (visible from start to end) |
| `'0.25 0.75'` | Middle 50% of the stroke is visible |
| `'1 1'` | Stroke fully erased from the front (zero-length visible segment at end) |

**Draw → erase sequence.** A two-step timeline animates from hidden to drawn, then erases from the front:

```js
// Step 1: draw the stroke (end advances from 0 to 1, start stays at 0)
.add(svg.createDrawable('.ring'), { draw: ['0 0', '0 1'] })
// Step 2: erase from the front (start advances from 0 to 1, end stays at 1)
.add(svg.createDrawable('.ring'), { draw: ['0 1', '1 1'] })
```

After step 2 the state is `'1 1'` (zero-length visible segment at the end of the path), which visually matches the initial `'0 0'` state — so the loop restarts cleanly.

`svg.createDrawable` is called once per `.add()` call (not stored in a variable), so the same selector can be re-used across multiple steps.

### Demos in this repo

Three demonstrations live in `_posts/2026-01-01-testing.md` under `## Anime.js animations`:

| Demo | APIs used | What it shows |
|---|---|---|
| Staggered wave | `animate`, `stagger`, `loop: true`, `alternate: true` | 9 dots bounce in a rolling wave; `alternate` reverses the animation each loop so it doesn't snap back |
| SVG concentric circles | `createTimeline`, `svg.createDrawable`, `stagger` with `from: 'last'` | 4 rings draw themselves inward, then erase outward, on repeat |
| Grid ripple | `createTimeline`, `stagger` with `grid` and `from: 'center'` | 6×6 grid scales in from the centre then collapses back |

### Updating the bundle

Copy the new bundle from `anime/dist/bundles/anime.umd.min.js` to `assets/js/anime.min.js`. No config change is needed. The `anime/` folder itself must remain in the `exclude` list in `_config.yml`.

### Files

| File | Purpose |
|---|---|
| `assets/js/anime.min.js` | Anime.js v4.3.6 UMD bundle (static asset served to the browser) |
| `anime/dist/bundles/anime.umd.min.js` | Source bundle (excluded from Jekyll build) |

---

## TikZ Diagrams

TikZ/LaTeX diagrams are compiled to SVG at Jekyll build time by a custom Liquid block tag implemented in `_plugins/tikz.rb`. No Docker, no external watcher — the plugin shells out to `pdflatex` and `dvisvgm`, both provided by the Nix flake's `texlivePkgs` derivation.

### Nix flake integration

The `flake.nix` builds a texlive environment via `pkgs.texlive.combine`:

```nix
texlivePkgs = pkgs.texlive.combine {
  inherit (pkgs.texlive)
    scheme-basic   # latex, pdflatex, plain TeX, essential packages
    standalone     # standalone document class (crops output to content)
    pgf            # TikZ / PGF + libraries (arrows, shapes, positioning…)
    amsmath        # AMS math environments + latexsym symbols
    amscls         # AMS document classes (amsthm, amsart…)
    dvisvgm        # DVI/PDF → SVG converter
    ;
};
deps = with pkgs; [ env ruby bundixcli texlivePkgs ];
```

`deps` is used for both `packages` (the `nix run` outputs) and `devShells.default` (the `nix develop` shell), so `pdflatex` and `dvisvgm` are on PATH in every entry point. After changing `flake.nix` run `nix flake update` if you also want to pin new nixpkgs revisions, or just rebuild with `nix develop` / `nix run`.

### Jekyll plugin (`_plugins/tikz.rb`)

**Tag syntax:**

```markdown
{% tikz diagram_name %}
\begin{tikzpicture}
  \draw[->] (0,0) -- (2,0) node[right] {$x$};
  \draw[->] (0,0) -- (0,2) node[above] {$y$};
\end{tikzpicture}
{% endtikz %}
```

The `diagram_name` label is used as the base filename; it is sanitised (non-word characters stripped) and must be unique per site. A second optional keyword `inline` switches to inline-SVG mode (see below).

**Compilation pipeline:**

```
_posts/my-post.md
  └─ {% tikz name %} block
       └─ _plugins/tikz.rb (render method)
            ├─ writes  _tikz/name-<md5>.tex
            ├─ runs    pdflatex -interaction=nonstopmode -halt-on-error
            │           -output-directory=_tikz   _tikz/name-<md5>.tex
            │           → _tikz/name-<md5>.pdf
            ├─ runs    dvisvgm --pdf --no-fonts --exact-bbox
            │           --output=assets/tikz/name-<md5>.svg
            │           _tikz/name-<md5>.pdf
            │           → assets/tikz/name-<md5>.svg
            └─ returns <img class="tikz-svg" src="/assets/tikz/name-<md5>.svg">
```

**Caching.** The SVG filename includes an MD5 hash of the complete LaTeX source (preamble + body). If `assets/tikz/name-<md5>.svg` already exists on disk, the plugin skips pdflatex and dvisvgm entirely. This makes incremental rebuilds fast: only changed or new diagrams are recompiled.

**Static file registration.** Jekyll scans for source files to copy to `_site/` during the *read* phase, which runs before the *render* phase where the plugin executes. Files created by the plugin mid-build are therefore invisible to the normal scan. The plugin adds each generated SVG to `site.static_files` explicitly so Jekyll copies it to `_site/assets/tikz/` during the write phase. Without this, `jekyll serve` returns 404 for all TikZ SVGs.

**dvisvgm flags:**
- `--pdf` — treat the input as PDF (not DVI); pdflatex produces PDF natively.
- `--no-fonts` — replace font glyphs with SVG paths. The resulting SVG has no dependency on system or browser fonts. Text is not selectable but files render identically everywhere.
- `--exact-bbox` — use TeX's precise bounding-box data rather than estimating it from glyph outlines.

**Preamble.** The plugin wraps every diagram in:

```latex
\documentclass{standalone}
\usepackage{tikz}
\usepackage{amsmath,amssymb,latexsym}
\usetikzlibrary{
  arrows, arrows.meta, automata,
  backgrounds, calc, decorations.markings,
  fit, patterns, positioning,
  shapes, shapes.geometric
}
```

`standalone` crops the PDF to the diagram's bounding box. **Do not add `[varwidth]` to `\documentclass`** — the `varwidth` package is not included in the Nix flake's `texlivePkgs` and will cause a `File 'varwidth.sty' not found` error. To add extra packages or libraries for a single post, embed a raw `\usepackage{}` or `\usetikzlibrary{}` call at the top of the block — pdflatex processes them before `\begin{tikzpicture}`.

**Showing tikz tag syntax in post prose.** Liquid processes the post file before Kramdown, so `` `{% tikz %}` `` in a paragraph will be treated as an actual Liquid tag and open a block looking for `{% endtikz %}`. Escape it with `{% raw %}`/`{% endraw %}`:

```markdown
Use the `{% raw %}{% tikz name %}...{% endtikz %}{% endraw %}` block tag.
```

**Directory layout:**

| Path | Role | Committed? |
|---|---|---|
| `_tikz/` | Intermediate files (.tex, .pdf, .log, .aux) | No (starts with `_`; also in `.gitignore`) |
| `assets/tikz/` | Final SVG assets served to the browser | Optional — see `.gitignore` comments |

`_tikz/` starts with `_` so Jekyll ignores it automatically. `assets/tikz/` is served but is not a Jekyll-source directory — Jekyll copies it verbatim into `_site/`.

**Error handling.** If pdflatex or dvisvgm fails, the plugin logs the last 10 lines of their output at `Jekyll.logger.error` level and renders a `<div class="tikz-error">` placeholder in the page instead of crashing the build.

### Output modes

**Standard (`<img>` tag):**

```markdown
{% tikz my_diagram %}
...
{% endtikz %}
```

Renders `<img class="tikz-svg" src="/assets/tikz/my_diagram-<md5>.svg" …>`. The SVG is loaded as an image; CSS on the page cannot reach its internal elements. This is correct for static diagrams.

**Inline (`<div>` + JS injection):**

```markdown
{% tikz my_diagram inline %}
...
{% endtikz %}
```

Renders `<div class="tikz-inline" id="tikz-my_diagram" data-tikz-src="/assets/tikz/…">`. On `DOMContentLoaded`, `tikz-loader.js` fetches the SVG and injects it as inline DOM. Inner elements are then reachable by CSS and JavaScript, enabling animation.

### Inline animated SVG — how it works

#### 1. Build time: plugin produces a placeholder `<div>`

The plugin compiles the diagram to an SVG file normally (pdflatex → dvisvgm), then instead of returning an `<img>`, returns:

```html
<div class="tikz-inline" id="tikz-my_diagram" data-tikz-src="/assets/tikz/my_diagram-<md5>.svg"></div>
```

The div is empty. It holds two pieces of metadata: the SVG URL (`data-tikz-src`) and a stable identity (`id`). The SVG file sits on disk as a standalone file.

#### 2. Runtime: `tikz-loader.js` fetches and injects

On `DOMContentLoaded`, the loader finds every `.tikz-inline[data-tikz-src]` and for each one:

1. Reads `data-tikz-src` to get the URL.
2. `fetch(src)` — retrieves the SVG as plain text.
3. Applies the font-scope fix (see below).
4. Sets `container.innerHTML = scoped` — SVG markup is parsed and inserted as real child DOM nodes.

After injection the page DOM looks like:

```html
<div class="tikz-inline tikz-loaded" id="tikz-my_diagram">
  <svg xmlns="..." viewBox="...">
    <style>text.tikz-my_diagram-f0 { font-family: tikz-my_diagram-cmr12; }</style>
    <path d="..." />
  </svg>
</div>
```

The `<svg>` is a real DOM subtree — every `<path>`, `<text>`, `<g>` is individually addressable.

#### 3. Why `<img>` cannot be animated but inline SVG can

With `<img src="…">` the browser sandboxes the SVG: CSS on the parent page cannot reach inside it and `querySelector` cannot find its elements.

With inline injection the SVG's elements are full DOM nodes in the same document, so:

```css
#tikz-my_diagram svg { animation: spin 3s linear infinite; }
#tikz-my_diagram path:first-child { fill: red; }
@keyframes spin { to { transform: rotate(360deg); } }
```

These rules reach directly into the SVG. Individual paths, groups, and text nodes are all targetable.

#### 4. Font-scope fix

`dvisvgm --no-fonts` converts glyphs to outlines but may still emit a `<style>` block with terse class names:

```svg
<style>
  text.f0 { font-family: cmr12; }
</style>
<text class="f0">hello</text>
```

If two inline SVGs share the page, the second SVG's `text.f0` rule overwrites the first's. `tikz-loader.js` rewrites class names before injection using the container id as a prefix:

| Pattern in SVG text | Replacement |
|---|---|
| `font-family:cmr12` | `font-family:tikz-my_diagram-cmr12` |
| `text.f0` (in `<style>`) | `text.tikz-my_diagram-f0` |
| `class="f0"` (on elements) | `class="tikz-my_diagram-f0"` |

Two SVGs with different ids get fully non-overlapping style rules.

#### 5. Loading state

`.tikz-inline:not(.tikz-loaded):not(.tikz-error)` has `min-height: 2rem` so the page doesn't jump while the SVG is in flight. Once `innerHTML` is set the loader adds `.tikz-loaded`, removing that rule and letting the SVG's natural height take over.

#### 6. CSS authoring pattern

Add a `<style>` block after the `{% tikz %}` tag:

```html
{% tikz spinning_ring inline %}
\begin{tikzpicture}
  \draw[thick,blue] (0,0) circle (1cm);
\end{tikzpicture}
{% endtikz %}

<style>
#tikz-spinning_ring svg {
  animation: spin 3s linear infinite;
  transform-origin: center;
}
@keyframes spin { to { transform: rotate(360deg); } }
</style>
```

### tikz-loader.js — font scoping

`dvisvgm` generates SVG with `<style>` blocks containing font rules like `text.f0 { font-family: cmr12; }`. When multiple inline SVGs appear on the same page these class names collide and the wrong font is applied to elements in the second and later SVGs.

`tikz-loader.js` rewrites each SVG's font class names before injecting it:

1. `font-family:cmr12` → `font-family:tikz-my_diagram-cmr12` (scoped font name)
2. `text.f0` → `text.tikz-my_diagram-f0` (scoped CSS selector)
3. `class="f0"` → `class="tikz-my_diagram-f0"` (scoped element class)

The prefix is the container's `id` attribute (e.g. `tikz-my_diagram`), which is unique per diagram. This makes each SVG's styles fully self-contained regardless of how many appear on the page.

### SVG IDs for TikZ elements (DVI path, advanced)

For fine-grained CSS / JS control over individual TikZ elements, it is possible to assign SVG `<g id="…">` wrappers using a `\special{dvisvgm:raw}` trick (described in `TikZ-SVG-animations.md`). This requires using the DVI compilation path (`latex` → `dvisvgm` without `--pdf`) rather than the PDF path used by default. The plugin currently uses the PDF path for maximum package compatibility. To switch:

1. Change `pdflatex` to `latex` in the `compile` method of `_plugins/tikz.rb`.
2. Change `pdf_path` / `--pdf` / `.pdf` references to `dvi_path` / `.dvi`.
3. Remove `--pdf` from the dvisvgm call.

The `\special` trick in TikZ:

```latex
\tikzset{
  svgid/.style={
    execute at begin scope={\special{dvisvgm:raw <g id="#1">}},
    execute at end scope={\special{dvisvgm:raw </g>}},
  }
}

\begin{scope}[svgid=my-group]
  \draw ...
\end{scope}
```

### CSS layout classes

Wrap the `{% tikz %}` tag in a `<div>` to control its layout:

```html
<!-- Centred, 50% width (default block) -->
<div class="block-tikz">{% tikz name %}...{% endtikz %}</div>

<!-- Wider — 80% width -->
<div class="block-tikz large">{% tikz name %}...{% endtikz %}</div>

<!-- Inline formula-height -->
<span class="inline-tikz">{% tikz name %}...{% endtikz %}</span>
```

All classes are defined in `_sass/tikz.scss` and use the project's 600 px mobile breakpoint.

### Adding TikZ libraries

To add a library for one post only, put `\usetikzlibrary{}` at the top of the block body:

```latex
{% tikz automata_example %}
\usetikzlibrary{automata,positioning}
\begin{tikzpicture}[shorten >=1pt,auto]
  \node[state,initial]  (q0) {$q_0$};
  \node[state,accepting](q1) [right=of q0] {$q_1$};
  \path[->] (q0) edge node {a} (q1);
\end{tikzpicture}
{% endtikz %}
```

To add a library globally, add it to the `PREAMBLE` constant in `_plugins/tikz.rb`.

### Files

| File | Purpose |
|---|---|
| `_plugins/tikz.rb` | Liquid block tag — compiles LaTeX, manages caching, returns HTML |
| `assets/js/tikz-loader.js` | Fetches and injects inline SVGs; fixes font-class scoping |
| `_sass/tikz.scss` | `.tikz-svg`, `.tikz-inline`, `.block-tikz`, `.inline-tikz`, `.tikz-error` |
| `_tikz/` | Working directory for intermediate files (never served, never committed) |
| `assets/tikz/` | Compiled SVG assets (served; optionally committed — see `.gitignore`) |
