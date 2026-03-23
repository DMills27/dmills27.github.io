// highlight-comments.js — Medium-style text annotation for Jekyll posts.
//
// Usage: highlight any text within a post to open a comment tooltip.
// Annotations with at least one comment are persisted in localStorage
// and restored on the next page load.
//
// Data interface:
//   No front-matter or HTML attributes needed. The script attaches
//   automatically to the `.post` element on post pages.
//
// localStorage key: `hc:<pathname>` → JSON array of annotation records.

(() => {
  'use strict';

  // ── Configuration ────────────────────────────────────────────────────────
  const POST_SELECTOR = '.post';

  // Elements within .post that must never be annotatable.
  const EXCLUDED = [
    '.post-info', '.post-title', '.tags-clouds',
    '.hc-annotation', '.hc-tooltip',
    'pre', 'code', '.highlight',
  ];

  const STORAGE_KEY = `hc:${window.location.pathname}`;

  // ── State ────────────────────────────────────────────────────────────────
  // id → { element, comments[], committed, serialized }
  const annotations      = new Map();
  let   activeTooltip    = null;
  let   activeAnnotation = null;
  let   isProcessing     = false;

  // Browsers fire a `click` event after every mouseup, even after a drag
  // selection. The click target is recorded at mousedown time, so after we
  // mutate the DOM in `mouseup` (wrapping text in .hc-annotation) the
  // subsequent click sees the pre-mutation element — not the new span —
  // and the click-outside handler immediately closes the tooltip we just
  // opened. This flag suppresses exactly that one spurious close.
  let suppressNextClick  = false;

  // ── Utilities ────────────────────────────────────────────────────────────
  function uid() {
    // crypto.randomUUID is available in all modern browsers.
    return (typeof crypto.randomUUID === 'function')
      ? crypto.randomUUID()
      : Date.now().toString(36) + Math.random().toString(36).slice(2);
  }

  // Escape user text before setting on any DOM property that interprets HTML.
  function escapeHtml(str) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function getPost() {
    return document.querySelector(POST_SELECTOR);
  }

  // ── Range validation ─────────────────────────────────────────────────────
  function isRangeWrapSafe(range) {
    if (!range || range.collapsed) return false;

    const post = getPost();
    if (!post) return false;

    // Walk to the nearest Element so that Element.contains() works reliably.
    let commonEl = range.commonAncestorContainer;
    if (commonEl.nodeType === Node.TEXT_NODE) commonEl = commonEl.parentElement;
    if (!post.contains(commonEl)) return false;

    // Must not be inside an excluded element.
    let node = range.commonAncestorContainer;
    while (node && node !== post) {
      if (node.nodeType === Node.ELEMENT_NODE) {
        for (const sel of EXCLUDED) {
          if (node.matches(sel)) return false;
        }
      }
      node = node.parentNode;
    }

    // Must have non-whitespace text content.
    if (!range.toString().trim()) return false;

    // Must not be a sub-selection WITHIN an existing annotation.
    // cloneContents() only sees nodes *inside* the range, so an annotation
    // that fully contains the selection (the wrapping span is outside the
    // range) would not be caught by the fragment walker below.
    // We check the live DOM ancestor chain instead.
    let ancestor = range.commonAncestorContainer;
    while (ancestor && ancestor !== post) {
      if (ancestor.classList?.contains('hc-annotation')) return false;
      ancestor = ancestor.parentNode;
    }

    // Must not cross block-level elements or span an existing annotation
    // (handles partial overlaps where the span IS inside the range).
    const fragment = range.cloneContents();
    const walker   = document.createTreeWalker(fragment, NodeFilter.SHOW_ELEMENT);
    let el;
    while ((el = walker.nextNode())) {
      if (el.classList?.contains('hc-annotation') ||
          ['DIV', 'P', 'H1', 'H2', 'H3', 'H4', 'BLOCKQUOTE', 'PRE'].includes(el.nodeName)) {
        return false;
      }
    }
    return true;
  }

  // ── Serialization ─────────────────────────────────────────────────────────
  // Identifies a selection by block index + character offset so it can be
  // faithfully re-wrapped after a page reload on static content.
  //
  // Block index: position of the containing block element within the ordered
  //   list of all annotatable block elements inside .post.
  // textStart: character offset of the selection start within the block's
  //   concatenated text content (as seen by a text-node TreeWalker).
  // textLength: length of the selected text (range.toString().length).
  // selectedText: stored for a round-trip sanity check on restore.

  function getAnnotatableBlocks() {
    const post = getPost();
    if (!post) return [];
    return [...post.querySelectorAll('p, li, h2, h3, h4, blockquote')]
      .filter(el => !el.closest('.post-info, .tags-clouds, .highlight, pre, code'));
  }

  function serializeRange(range) {
    const blocks = getAnnotatableBlocks();

    // Walk up from the start container to find the owning block element.
    let blockEl = range.startContainer.nodeType === Node.TEXT_NODE
      ? range.startContainer.parentElement
      : range.startContainer;

    while (blockEl && !blocks.includes(blockEl)) {
      blockEl = blockEl.parentElement;
    }
    if (!blockEl) return null;

    const blockIdx = blocks.indexOf(blockEl);

    // Count characters in text nodes up to (and including the offset within)
    // the start container to get the absolute character position.
    const walker = document.createTreeWalker(blockEl, NodeFilter.SHOW_TEXT);
    let charCount = 0;
    while (walker.nextNode()) {
      const tn = walker.currentNode;
      if (tn === range.startContainer) {
        charCount += range.startOffset;
        break;
      }
      charCount += tn.textContent.length;
    }

    return {
      blockIdx,
      textStart:    charCount,
      textLength:   range.toString().length,
      selectedText: range.toString(),
    };
  }

  function deserializeRange(record) {
    const { blockIdx, textStart, textLength, selectedText } = record;
    const blocks  = getAnnotatableBlocks();
    const blockEl = blocks[blockIdx];
    if (!blockEl) return null;

    const walker = document.createTreeWalker(blockEl, NodeFilter.SHOW_TEXT);
    let charCount = 0;
    let startNode = null, startOff = 0;
    let endNode   = null, endOff   = 0;

    while (walker.nextNode()) {
      const tn  = walker.currentNode;
      const len = tn.textContent.length;

      if (!startNode && charCount + len > textStart) {
        startNode = tn;
        startOff  = textStart - charCount;
      }
      if (startNode && charCount + len >= textStart + textLength) {
        endNode = tn;
        endOff  = textStart + textLength - charCount;
        break;
      }
      charCount += len;
    }

    if (!startNode || !endNode) return null;

    const range = document.createRange();
    range.setStart(startNode, startOff);
    range.setEnd(endNode, endOff);

    // Sanity check: the re-created range must reproduce the original text.
    if (range.toString() !== selectedText) return null;

    return range;
  }

  // ── localStorage ─────────────────────────────────────────────────────────
  function loadFromStorage() {
    try {
      return JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    } catch { return []; }
  }

  function saveToStorage() {
    const data = [];
    for (const [id, entry] of annotations) {
      if (entry.serialized && entry.comments.length > 0) {
        data.push({ id, ...entry.serialized, comments: entry.comments });
      }
    }
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
    } catch { /* storage full or unavailable — fail silently */ }
  }

  // ── DOM helpers ───────────────────────────────────────────────────────────
  // Wraps a range in a .hc-annotation span and returns that span.
  // The range is consumed (extractContents mutates the DOM).
  function wrapRange(range, id) {
    const wrapper = document.createElement('span');
    wrapper.className  = 'hc-annotation';
    wrapper.dataset.id = id;

    const bubble = document.createElement('span');
    bubble.className = 'hc-bubble';
    bubble.setAttribute('aria-hidden', 'true');

    // extractContents preserves all child elements (inline formatting).
    const fragment = range.extractContents();
    wrapper.appendChild(fragment);
    wrapper.appendChild(bubble);
    range.insertNode(wrapper);

    wrapper.addEventListener('click', e => {
      e.stopPropagation();
      openTooltip(wrapper);
    });

    return wrapper;
  }

  // Updates the bubble to show the comment count (or the 💬 icon if zero).
  function updateBubble(entry) {
    const bubble = entry.element?.querySelector('.hc-bubble');
    if (!bubble) return;
    const n = entry.comments.length;
    bubble.textContent = n > 0 ? String(n) : '💬';
  }

  // Removes the annotation wrapper and reinserts its original child nodes
  // (minus the bubble) to restore the exact original DOM structure.
  function unwrapAnnotation(entry) {
    const wrapper = entry.element;
    const parent  = wrapper?.parentNode;
    if (!parent) return;

    const frag = document.createDocumentFragment();
    for (const child of [...wrapper.childNodes]) {
      if (!child.classList?.contains('hc-bubble')) frag.appendChild(child);
    }
    parent.replaceChild(frag, wrapper);
  }

  // ── Tooltip ───────────────────────────────────────────────────────────────
  function openTooltip(annotationEl) {
    closeTooltip(); // close any existing tooltip first

    const id    = annotationEl.dataset.id;
    const entry = annotations.get(id);
    if (!entry) return;

    const tooltip = document.createElement('div');
    tooltip.className         = 'hc-tooltip';
    tooltip.dataset.annotationId = id;

    // Position below the annotation. The tooltip uses `position: fixed` so
    // we use getBoundingClientRect (viewport coords) with no scroll offset.
    const rect = annotationEl.getBoundingClientRect();
    tooltip.style.top  = `${rect.bottom + 6}px`;
    tooltip.style.left = `${rect.left}px`;

    renderTooltipContents(tooltip, entry);
    document.body.appendChild(tooltip);

    // Clamp to viewport after a render frame so we know the tooltip's size.
    requestAnimationFrame(() => clampTooltip(tooltip, rect));

    activeTooltip    = tooltip;
    activeAnnotation = annotationEl;
  }

  function clampTooltip(tooltip, annotationRect) {
    const tr = tooltip.getBoundingClientRect();
    if (tr.right > window.innerWidth - 8) {
      tooltip.style.left = `${Math.max(8, window.innerWidth - tr.width - 8)}px`;
    }
    // Flip above the annotation if it overflows the bottom edge.
    if (tr.bottom > window.innerHeight - 8) {
      tooltip.style.top = `${annotationRect.top - tr.height - 6}px`;
    }
  }

  function repositionTooltip() {
    if (!activeTooltip || !activeAnnotation) return;
    const rect = activeAnnotation.getBoundingClientRect();
    activeTooltip.style.top  = `${rect.bottom + 6}px`;
    activeTooltip.style.left = `${rect.left}px`;
    clampTooltip(activeTooltip, rect);
  }

  function renderTooltipContents(tooltip, entry) {
    tooltip.innerHTML = '';

    // Existing comments — build DOM nodes so user text is never eval'd as HTML.
    entry.comments.forEach(c => {
      const row    = document.createElement('div');
      row.className = 'hc-comment';

      const avatar = document.createElement('div');
      avatar.className = 'hc-avatar';
      // Assign color via the style property — not an HTML string — to
      // prevent CSS injection if the value were ever untrusted.
      avatar.style.backgroundColor = c.color || '#5ae';
      avatar.textContent = (c.author || 'Y')[0].toUpperCase();

      const body   = document.createElement('div');
      const author = document.createElement('div');
      author.className  = 'hc-comment-author';
      author.textContent = c.author || 'You'; // textContent is safe

      const text   = document.createElement('div');
      text.className  = 'hc-comment-text';
      text.textContent = c.text; // textContent is safe

      body.append(author, text);
      row.append(avatar, body);
      tooltip.appendChild(row);
    });

    // Input area.
    const textarea = document.createElement('textarea');
    textarea.className   = 'hc-input';
    textarea.rows        = 2;
    textarea.placeholder = 'Add a comment…';

    const btn = document.createElement('button');
    btn.className = 'hc-post-btn';
    btn.textContent = 'Post';
    btn.disabled    = true;

    textarea.addEventListener('input', () => {
      btn.disabled = !textarea.value.trim();
    });

    // Ctrl/Cmd+Enter submits — consistent with most comment interfaces.
    textarea.addEventListener('keydown', e => {
      if ((e.ctrlKey || e.metaKey) && e.key === 'Enter' && !btn.disabled) {
        btn.click();
      }
    });

    btn.addEventListener('click', () => {
      const text = textarea.value.trim();
      if (!text) return;

      entry.comments.push({ author: 'You', color: '#5ae', text, timestamp: Date.now() });
      entry.committed = true;
      updateBubble(entry);
      saveToStorage();
      renderTooltipContents(tooltip, entry); // re-render with new comment
    });

    tooltip.appendChild(textarea);
    tooltip.appendChild(btn);

    // Focus without scrolling the page — the tooltip is already in view.
    setTimeout(() => textarea.focus({ preventScroll: true }), 10);
  }

  function closeTooltip() {
    if (!activeTooltip || !activeAnnotation) return;

    const id    = activeTooltip.dataset.annotationId;
    const entry = annotations.get(id);

    // An annotation with no comments was never committed — remove the highlight.
    if (entry && entry.comments.length === 0 && !entry.committed) {
      unwrapAnnotation(entry);
      annotations.delete(id);
    }

    activeTooltip.remove();
    activeTooltip    = null;
    activeAnnotation = null;
  }

  // ── Selection handler ─────────────────────────────────────────────────────
  document.addEventListener('mouseup', () => {
    if (isProcessing) return;

    const sel = window.getSelection();
    if (!sel || sel.isCollapsed) return;

    const range = sel.getRangeAt(0);
    if (!isRangeWrapSafe(range)) {
      sel.removeAllRanges();
      return;
    }

    // Lock synchronously. There is no async gap between the check above and
    // the DOM work below, so a second rapid mouseup is safely deferred.
    isProcessing = true;

    const id = uid();
    try {
      // Validate BEFORE extracting so the DOM is not left in a broken state
      // if the selection turns out to be empty after cloning.
      const previewText = range.cloneContents().textContent.trim();
      if (!previewText) throw new Error('Empty selection');

      // Serialize the range position BEFORE wrapRange mutates the DOM.
      const serialized = serializeRange(range.cloneRange());

      const wrapper = wrapRange(range.cloneRange(), id);
      sel.removeAllRanges();

      annotations.set(id, {
        element:    wrapper,
        comments:   [],
        committed:  false,
        serialized,
      });

      openTooltip(wrapper);
      suppressNextClick = true; // swallow the click that always follows mouseup
    } catch (e) {
      console.warn('[highlight-comments] Failed to create annotation:', e);
    } finally {
      // Release immediately — all synchronous DOM work is done.
      isProcessing = false;
    }
  });

  // ── Restore persisted annotations ─────────────────────────────────────────
  function restoreAnnotations() {
    const records = loadFromStorage();
    for (const record of records) {
      const { id, comments } = record;
      try {
        const range = deserializeRange(record);
        if (!range) continue;
        if (!isRangeWrapSafe(range)) continue;

        // Serialize again from the fresh range to get accurate block/offset
        // values in the (possibly already-modified) DOM.
        const serialized = serializeRange(range.cloneRange());

        const wrapper = wrapRange(range, id);
        annotations.set(id, {
          element:    wrapper,
          comments:   comments || [],
          committed:  (comments || []).length > 0,
          serialized,
        });

        updateBubble(annotations.get(id));
      } catch (e) {
        console.warn('[highlight-comments] Failed to restore annotation:', id, e);
      }
    }
  }

  // ── Global event handlers ─────────────────────────────────────────────────
  document.addEventListener('click', e => {
    // Consume the flag and skip — this is the click that immediately follows
    // the mouseup that created the annotation.
    if (suppressNextClick) {
      suppressNextClick = false;
      return;
    }
    // A click inside the annotation or the tooltip must not close the tooltip.
    if (!e.target.closest('.hc-annotation') && !e.target.closest('.hc-tooltip')) {
      closeTooltip();
    }
  });

  document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeTooltip();
  });

  // Reposition the tooltip as the user scrolls so it stays anchored to its
  // annotation rather than drifting or floating in the wrong place.
  document.addEventListener('scroll', repositionTooltip, { passive: true });
  window.addEventListener('resize', repositionTooltip);

  // ── Init ─────────────────────────────────────────────────────────────────
  function init() {
    if (!getPost()) return; // not a post page — do nothing
    restoreAnnotations();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
