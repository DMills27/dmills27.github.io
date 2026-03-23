/**
 * tikz-loader.js
 *
 * Fetches TikZ SVG files and injects them inline into
 * .tikz-inline[data-tikz-src] containers.
 *
 * Inline SVGs (unlike <img> tags) are part of the page DOM, so:
 *   - CSS rules on the page can target SVG elements directly
 *   - CSS animations and transitions work on SVG children
 *   - JavaScript can manipulate inner elements
 *
 * FONT / STYLE SCOPING
 * ────────────────────
 * dvisvgm generates font class names like "f0", "f1" in a <style> block.
 * When multiple SVGs are injected on the same page these names collide and
 * the wrong font is applied.  This loader rewrites each SVG's class names
 * to include the container id as a prefix, making them unique.
 *
 * USAGE
 * ─────
 * Containers are produced by {% tikz name inline %} in a post.
 * The loader runs automatically on DOMContentLoaded — no manual call needed.
 *
 * To animate an injected SVG with CSS, target its scoped class names:
 *
 *   /* In the post's <style> block (after the {% tikz %} block) * /
 *   #tikz-my_diagram path {
 *     animation: spin 2s linear infinite;
 *   }
 *   @keyframes spin {
 *     to { transform: rotate(360deg); }
 *   }
 */

(function () {
  'use strict';

  function loadTikz(container) {
    var src = container.getAttribute('data-tikz-src');
    var id  = container.id;
    if (!src || !id) return;

    fetch(src)
      .then(function (res) {
        if (!res.ok) throw new Error('HTTP ' + res.status + ' fetching ' + src);
        return res.text();
      })
      .then(function (svgText) {
        // ── Font-scope fix ────────────────────────────────────────────────
        // dvisvgm emits SVG with internal <style> blocks like:
        //   text.f0 { font-family: cmr12; }
        // and elements like:
        //   <text class="f0">
        // Prefix every font class with the container id so classes from
        // different SVGs don't overlap.

        var prefix = id;

        var scoped = svgText
          // Rename font-family values in <style>: cmr12 → {id}-cmr12
          .replace(/\bfont-family:([^\s;}"]+)/g, function (_, name) {
            return 'font-family:' + prefix + '-' + name;
          })
          // Rename class selectors in <style>: text.f0 → text.{id}-f0
          .replace(/\btext\.f(\d+)\b/g, function (_, n) {
            return 'text.' + prefix + '-f' + n;
          })
          // Rename class attributes on elements: class="f0" → class="{id}-f0"
          .replace(/\bclass="f(\d+)"/g, function (_, n) {
            return 'class="' + prefix + '-f' + n + '"';
          });

        container.innerHTML = scoped;
        container.classList.add('tikz-loaded');
      })
      .catch(function (err) {
        console.error('[tikz-loader]', err);
        container.textContent = '\u26A0 Failed to load ' + src;
        container.classList.add('tikz-error');
      });
  }

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.tikz-inline[data-tikz-src]').forEach(loadTikz);
  });
}());
