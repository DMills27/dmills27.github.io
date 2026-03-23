// popup-lite.js — rich hover popups for links with data-popup-* attributes
(() => {
  'use strict';

  // ── Timing constants ────────────────────────────────────────────────────
  // TRIGGER_DELAY: how long the cursor must rest on a link before the popup
  // appears. 750ms prevents popups from flashing on every accidental pass.
  const TRIGGER_DELAY    = 750;

  // FADEOUT_DELAY: grace period (ms) after the cursor leaves — prevents the
  // popup from vanishing the instant you accidentally drift off by a pixel.
  const FADEOUT_DELAY    = 100;

  // FADEOUT_DURATION: must match the CSS transition duration on .popup.
  const FADEOUT_DURATION = 250;

  // Breathing room (px) between cursor and popup edge.
  const BREATHING_X = 14;
  const BREATHING_Y = 10;

  // ── State ───────────────────────────────────────────────────────────────
  let container = null;

  // WeakMaps let GC collect entries automatically when the link is removed.
  const spawnTimers = new WeakMap(); // link → spawn setTimeout id
  const popupStore  = new WeakMap(); // link → popup element (may be detached)

  // Monotonically increasing z-index so the last-focused popup sits on top.
  let zCounter = 10;

  // ── Setup ───────────────────────────────────────────────────────────────
  function setup() {
    if (container) return;
    container = document.createElement('div');
    container.id = 'popup-container';
    document.body.appendChild(container);
  }

  // ── Small utilities ─────────────────────────────────────────────────────
  function clamp(val, lo, hi) {
    return Math.min(hi, Math.max(lo, val));
  }

  function clearSpawnTimer(link) {
    const id = spawnTimers.get(link);
    if (id != null) {
      clearTimeout(id);
      spawnTimers.delete(link);
    }
  }

  // Wrap plain-text abstracts in <p> so the CSS rules for p:first/last-child
  // work correctly.  Strings that already contain block-level HTML are left
  // as-is so authors can write richer markup if they want.
  function wrapAbstract(text) {
    if (!text) return '';
    return /<p[\s>]|<ul[\s>]|<ol[\s>]|<blockquote[\s>]/i.test(text)
      ? text
      : `<p>${text}</p>`;
  }

  // ── Build annotation data from element attributes ───────────────────────
  // This keeps the existing data-popup-* interface that posts already use,
  // so no post edits are needed.
  function annotationFrom(el) {
    return {
      title:    el.dataset.popupTitle    || 'Untitled',
      url:      el.href                  || '#',
      authors:  el.dataset.popupAuthor   || '',
      date:     el.dataset.popupDate     || '',
      tags:     el.dataset.popupTags
                  ? el.dataset.popupTags.split(',').map(s => s.trim()).filter(Boolean)
                  : [],
      abstract: el.dataset.popupAbstract || '',
      image:    el.dataset.popupImage    || '',
    };
  }

  // ── Z-index / focus management ──────────────────────────────────────────
  // Multiple popups can be open at the same time.  The most recently
  // interacted-with one gets a higher z-index and the .focused border style.
  function bringToFront(popup) {
    popup.style.zIndex = ++zCounter;
    container.querySelectorAll('.popup.focused')
             .forEach(p => p.classList.remove('focused'));
    popup.classList.add('focused');
  }

  // ── Build popup DOM + interactions ──────────────────────────────────────
  function buildPopup(ann) {
    const popup = document.createElement('div');
    popup.className = 'popup';

    // -- Title bar ----------------------------------------------------------
    // The bar is a drag handle; the pin and close buttons sit at each end.
    const bar = document.createElement('div');
    bar.className = 'popup-titlebar';

    // Pin button: keeps popup alive after the cursor leaves.
    // Starts dim (.45 opacity) to indicate it is inactive.
    const pinBtn = document.createElement('button');
    pinBtn.className = 'popup-titlebar-btn pin-btn';
    pinBtn.title = 'Pin (keep open)';
    pinBtn.textContent = '📌';
    pinBtn.style.opacity = '.45';

    const titleEl = document.createElement('div');
    titleEl.className = 'popup-title';
    titleEl.textContent = ann.title;

    const closeBtn = document.createElement('button');
    closeBtn.className = 'popup-titlebar-btn';
    closeBtn.title = 'Close';
    closeBtn.textContent = '✕';

    bar.append(pinBtn, titleEl, closeBtn);

    // -- Scrollable body ----------------------------------------------------
    const scroll = document.createElement('div');
    scroll.className = 'popup-scroll';

    const body = document.createElement('div');
    body.className = 'popup-body';

    // Clickable title → opens target URL in a new tab.
    const titleP = document.createElement('p');
    titleP.className = 'annotation-title';
    const titleA = document.createElement('a');
    titleA.href = ann.url;
    titleA.target = '_blank';
    titleA.rel = 'noopener';
    titleA.textContent = ann.title;
    titleP.appendChild(titleA);
    body.appendChild(titleP);

    // Author + date meta line (omitted when both are absent).
    if (ann.authors || ann.date) {
      const meta = document.createElement('div');
      meta.className = 'annotation-meta';

      if (ann.authors) {
        const s = document.createElement('span');
        s.className = 'authors';
        s.textContent = ann.authors;
        meta.appendChild(s);
      }
      if (ann.date) {
        const s = document.createElement('span');
        s.className = 'date';
        s.textContent = ann.date;
        meta.appendChild(s);
      }
      body.appendChild(meta);
    }

    // Tag pills.  Tags link to the site's /tags/<tag> pages.
    if (ann.tags.length) {
      const tagsEl = document.createElement('div');
      tagsEl.className = 'annotation-tags';
      ann.tags.forEach(tag => {
        const a = document.createElement('a');
        a.className = 'annotation-tag';
        a.textContent = tag;
        a.href = `/tags/${tag}`;
        tagsEl.appendChild(a);
      });
      body.appendChild(tagsEl);
    }

    // Abstract blockquote (supports plain text or HTML).
    if (ann.abstract) {
      const abs = document.createElement('blockquote');
      abs.className = 'annotation-abstract';
      abs.innerHTML = wrapAbstract(ann.abstract);
      body.appendChild(abs);
    }

    // Optional preview image.
    if (ann.image) {
      const img = document.createElement('img');
      img.src = ann.image;
      img.alt = 'Preview';
      img.className = 'annotation-image';
      body.appendChild(img);
    }

    scroll.appendChild(body);
    popup.append(bar, scroll);

    // ── Interactions ────────────────────────────────────────────────────

    let pinned = false;

    // Drag ---------------------------------------------------------------
    // mousedown on the bar starts a drag; mousemove / mouseup on *document*
    // so the drag continues even if the cursor leaves the popup briefly.
    let dragging = false, dragOffX = 0, dragOffY = 0;

    bar.addEventListener('mousedown', e => {
      if (e.target === closeBtn || e.target === pinBtn) return;
      dragging = true;
      const r = popup.getBoundingClientRect();
      dragOffX = e.clientX - r.left;
      dragOffY = e.clientY - r.top;
      popup.classList.add('dragging');
      bringToFront(popup);
      e.preventDefault(); // prevent text selection during drag
    });

    document.addEventListener('mousemove', e => {
      if (!dragging) return;
      popup.style.left = clamp(e.clientX - dragOffX, 0,
                               window.innerWidth  - popup.offsetWidth)  + 'px';
      popup.style.top  = clamp(e.clientY - dragOffY, 0,
                               window.innerHeight - popup.offsetHeight) + 'px';
    });

    document.addEventListener('mouseup', () => {
      if (!dragging) return;
      dragging = false;
      popup.classList.remove('dragging');
    });

    // Bring to front on any click inside the popup -----------------------
    popup.addEventListener('mousedown', () => bringToFront(popup));

    // Pin toggle ---------------------------------------------------------
    pinBtn.addEventListener('click', () => {
      pinned = !pinned;
      popup._pinned = pinned;
      pinBtn.style.opacity = pinned ? '1' : '.45';
      pinBtn.title = pinned ? 'Unpin' : 'Pin (keep open)';
    });

    // Close --------------------------------------------------------------
    closeBtn.addEventListener('click', () => despawnPopup(popup));

    // Keep popup alive while the cursor is inside it --------------------
    popup.addEventListener('mouseenter', () => {
      if (popup._fadeTimer != null) {
        clearTimeout(popup._fadeTimer);
        popup._fadeTimer = null;
      }
    });

    popup.addEventListener('mouseleave', () => {
      if (!popup._pinned) schedulePopupFade(popup);
    });

    return popup;
  }

  // ── Spawn and position a popup ──────────────────────────────────────────
  // We reuse the existing popup element if it is still in the DOM (e.g.
  // the user hovered away briefly and is hovering back in).  Otherwise we
  // build a fresh one.
  function spawnPopup(link, spawnX, spawnY) {
    const existing = popupStore.get(link);

    if (existing && existing.isConnected) {
      // Cancel any in-progress fade and make the popup visible again.
      if (existing._fadeTimer != null) {
        clearTimeout(existing._fadeTimer);
        existing._fadeTimer = null;
      }
      existing.classList.remove('fading');
      existing.classList.add('visible');
      bringToFront(existing);
      return existing;
    }

    // Build a fresh popup and attach it to the container.
    const popup = buildPopup(annotationFrom(link));
    popupStore.set(link, popup);
    container.appendChild(popup);

    // Park it off-screen so its dimensions are available but it is invisible.
    // requestAnimationFrame lets the browser complete one layout pass so that
    // offsetWidth / offsetHeight return the real rendered size.
    popup.style.left = '-9999px';
    popup.style.top  = '-9999px';

    requestAnimationFrame(() => {
      const pw = popup.offsetWidth;
      const ph = popup.offsetHeight;
      const vw = window.innerWidth;
      const vh = window.innerHeight;

      // Default: place the popup to the right of and below the cursor.
      // Flip to the other side if that would overflow the viewport.
      let x = spawnX + BREATHING_X;
      let y = spawnY + BREATHING_Y;

      if (x + pw > vw - 8) x = spawnX - pw - BREATHING_X;
      if (y + ph > vh - 8) y = spawnY - ph - BREATHING_Y;

      popup.style.left = clamp(x, 8, vw - pw - 8) + 'px';
      popup.style.top  = clamp(y, 8, vh - ph - 8) + 'px';

      // Fade in after positioning to avoid the brief flash at -9999px.
      popup.classList.add('visible');
    });

    bringToFront(popup);
    return popup;
  }

  // ── Fade out a popup (with FADEOUT_DELAY grace period) ──────────────────
  function schedulePopupFade(popup) {
    popup._fadeTimer = setTimeout(() => {
      popup._fadeTimer = null;
      popup.classList.add('fading');
      popup.classList.remove('visible', 'focused');
      // Remove from DOM after the CSS transition finishes.
      setTimeout(() => {
        if (popup.classList.contains('fading')) popup.remove();
      }, FADEOUT_DURATION + 50);
    }, FADEOUT_DELAY);
  }

  // ── Immediate close (from button or Escape key) ─────────────────────────
  function despawnPopup(popup) {
    popup._pinned = false;
    if (popup._fadeTimer != null) {
      clearTimeout(popup._fadeTimer);
      popup._fadeTimer = null;
    }
    popup.classList.add('fading');
    popup.classList.remove('visible', 'focused');
    setTimeout(() => popup.remove(), FADEOUT_DURATION + 50);
  }

  // ── Wire up every annotated link ────────────────────────────────────────
  function init() {
    setup();

    document.querySelectorAll('a[data-popup-title]').forEach(link => {
      // Track the cursor's last known position so the popup spawns at the
      // actual hover location, not the stale mouseenter position.
      let lastX = 0, lastY = 0;

      link.addEventListener('mouseenter', e => {
        lastX = e.clientX;
        lastY = e.clientY;
        clearSpawnTimer(link);

        // If an existing popup for this link is still in the DOM (e.g. fading),
        // rescue it immediately without waiting for TRIGGER_DELAY.
        const existing = popupStore.get(link);
        if (existing && existing.isConnected) {
          if (existing._fadeTimer != null) {
            clearTimeout(existing._fadeTimer);
            existing._fadeTimer = null;
          }
          existing.classList.remove('fading');
          existing.classList.add('visible');
          bringToFront(existing);
          return;
        }

        // First hover: wait for TRIGGER_DELAY before showing.
        const id = setTimeout(() => {
          spawnTimers.delete(link);
          spawnPopup(link, lastX, lastY);
        }, TRIGGER_DELAY);
        spawnTimers.set(link, id);
      });

      // Keep lastX/lastY current so the final spawn position is accurate.
      link.addEventListener('mousemove', e => {
        lastX = e.clientX;
        lastY = e.clientY;
      });

      link.addEventListener('mouseleave', () => {
        clearSpawnTimer(link);
        const popup = popupStore.get(link);
        if (popup && popup.isConnected && !popup._pinned) {
          schedulePopupFade(popup);
        }
      });

      // On the first click the popup isn't showing yet, so prevent navigation
      // and show the popup instead.  A subsequent click navigates normally.
      link.addEventListener('click', e => {
        const popup = popupStore.get(link);
        if (!popup || !popup.isConnected) {
          e.preventDefault();
          clearSpawnTimer(link);
          const r = link.getBoundingClientRect();
          spawnPopup(link, r.left + 10, r.bottom + 10);
        }
      });
    });

    // Escape closes all unpinned popups.
    document.addEventListener('keyup', e => {
      if (e.key !== 'Escape') return;
      container.querySelectorAll('.popup').forEach(popup => {
        if (!popup._pinned) despawnPopup(popup);
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
