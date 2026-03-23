/*
 * @author: Kaushik Gopal
 * @author: Michal Jirku
 * @author: dominic (rewrite)
 *
 * Tufte-style sidenotes for Jekyll/kramdown.
 *
 * On desktop (>= 600 px): sidenotes are shown to the right of the post,
 *   the .footnotes section at the bottom is hidden.
 * On mobile  (<  600 px): the standard .footnotes section is shown,
 *   sidenotes are removed.
 *
 * Rich footnote content — highlighted code blocks, images, and script-based
 * content such as anime.js animations — is preserved by deep-cloning the
 * footnote DOM node (cloneNode) rather than serialising to HTML.  Any
 * <script> elements found inside the clone are re-executed so that inline
 * animations run.
 *
 * NOTE on anime.js ID conflicts: if an animation inside a footnote creates
 * elements using document.getElementById it will resolve to the *first*
 * element with that ID in the document (the one in the post body, not the
 * sidenote copy).  Self-contained animations that build their own DOM via
 * document.createElement and capture the container in a closure work fine.
 */

(function () {
  'use strict';

  // Matches the 600 px mobile breakpoint in _sass/tale/_variables.scss
  var BREAKPOINT = 600;

  // Live list of built sidenotes so we can tear them down on mode change.
  // Each entry: { $div: jQuery<div.sidenote>, intervalId: number }
  var records = [];

  // ── Content helpers ───────────────────────────────────────────────────────

  // Deep-clone the <li> element, strip the footnote back-reference link,
  // and return a DocumentFragment of the remaining children.
  function extractContent(liEl) {
    var clone = liEl.cloneNode(true);
    clone.querySelectorAll('.reversefootnote, .footnote-backref').forEach(function (el) {
      el.remove();
    });
    var frag = document.createDocumentFragment();
    while (clone.firstChild) {
      frag.appendChild(clone.firstChild);
    }
    return frag;
  }

  // Replace every <script> inside container with a freshly created one so
  // the browser executes it.  Cloned <script> nodes are inert by spec.
  function rerunScripts(container) {
    container.querySelectorAll('script').forEach(function (old) {
      var s = document.createElement('script');
      Array.from(old.attributes).forEach(function (attr) {
        s.setAttribute(attr.name, attr.value);
      });
      s.textContent = old.textContent;
      old.parentNode.replaceChild(s, old);
    });
  }

  // ── Sidenote builder ──────────────────────────────────────────────────────

  // Build one sidenote and append it to <body>.
  // Returns { $div, intervalId } for later cleanup.
  // `prev` is the previous record (or null) used to prevent vertical overlap.
  function showSidenote(index, $sup, liEl, prev) {
    var div = document.createElement('div');
    div.className = 'sidenote';

    // Insert the ordinal label inside the first block element so it flows
    // inline with the opening text.  Without this, and without
    // `p { display: inline }`, the number would appear on its own line.
    var frag = extractContent(liEl);
    var header = document.createElement('span');
    header.className = 'sidenote-header';
    header.textContent = (index + 1) + '. ';
    var firstBlock = frag.querySelector('p, h2, h3, h4, pre, ul, ol, blockquote');
    if (firstBlock) {
      firstBlock.insertBefore(header, firstBlock.firstChild);
    } else {
      // Fallback: prepend the header directly (handles plain-text <li>)
      var headerWrapper = document.createElement('div');
      headerWrapper.appendChild(header);
      frag.insertBefore(headerWrapper, frag.firstChild);
    }
    div.appendChild(frag);

    // Re-execute any embedded scripts (e.g. anime.js animations)
    rerunScripts(div);

    var $div = $(div);

    function sizeit() {
      var $post = $('.post').first();
      if (!$post.length) return;

      var ww = $post.outerWidth() + $post.offset().left;
      var position = $sup.offset();

      // Push down below the previous sidenote if they would overlap.
      var minh = 0;
      if (prev) {
        minh = prev.$div.position().top + prev.$div.outerHeight() + 5;
      }

      $div.css({
        position: 'absolute',
        left: ww,
        top: Math.max(minh, position.top),
        'min-width': ww / 4,
        'max-width': ww / 3,
      });

      // Re-bind hover each time so stale handlers don't accumulate
      $sup.off('mouseenter.sn mouseleave.sn').on({
        'mouseenter.sn': function () { $div.addClass('sidenote-hover'); },
        'mouseleave.sn': function () { $div.removeClass('sidenote-hover'); },
      });
    }

    sizeit();
    $div.data('sizing-func', sizeit);
    var intervalId = setInterval(sizeit, 3000);

    $(document.body).append($div);

    return { $div: $div, intervalId: intervalId };
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  function buildSidenotes($footnotes, fnli) {
    if (records.length) return; // already built; wait for destroySidenotes first

    // Make the list measurable (it may be display:none from a prior mobile state)
    $footnotes.css('display', 'block');

    var prev = null;
    $('sup').has("a[href^='#fn:']").each(function (index) {
      var liEl = fnli.get(index);
      if (!liEl) return;
      var rec = showSidenote(index, $(this), liEl, prev);
      prev = rec;
      records.push(rec);
    });

    // Hide the bottom footnote list; sidenotes take over
    $footnotes.css('display', 'none');
  }

  function destroySidenotes($footnotes) {
    records.forEach(function (rec) {
      clearInterval(rec.intervalId);
      rec.$div.remove();
    });
    records = [];

    // Restore the standard footnote section
    $footnotes.css('display', '');
  }

  function reposition() {
    records.forEach(function (rec) {
      var f = rec.$div.data('sizing-func');
      if (f) f();
    });
  }

  function debounce(fn, ms) {
    var t;
    return function () { clearTimeout(t); t = setTimeout(fn, ms); };
  }

  // ── Entry point ───────────────────────────────────────────────────────────

  $(window).on('load', function () {
    var $footnotes = $('.footnotes');
    if (!$footnotes.length) return;

    // Temporarily expose footnotes for measurement
    $footnotes.css('display', 'block');
    var fnli = $footnotes.find('ol > li');

    // Initial render based on current viewport width
    if (window.innerWidth >= BREAKPOINT) {
      buildSidenotes($footnotes, fnli);
    }
    // else: leave .footnotes visible as normal on mobile

    // Switch modes when the viewport crosses the breakpoint
    var mql = window.matchMedia('(min-width: ' + BREAKPOINT + 'px)');
    mql.addEventListener('change', function (e) {
      if (e.matches) {
        buildSidenotes($footnotes, fnli);
      } else {
        destroySidenotes($footnotes);
      }
    });

    // Reposition on resize (desktop only; no-op on mobile where records=[])
    $(window).on('resize', debounce(reposition, 50));

    // Reposition after webfonts load (text reflow changes element heights)
    if (document.fonts) {
      document.fonts.onloadingdone = reposition;
    }
  });

})();
