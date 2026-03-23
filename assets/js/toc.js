(function () {
  var post    = document.querySelector('.post');
  var tocList = document.getElementById('toc-list');
  var toc     = document.getElementById('toc');
  if (!post || !tocList || !toc) return;

  /* --- build TOC from h2 / h3 inside .post --- */
  var headings = Array.prototype.slice.call(post.querySelectorAll('h2, h3'));

  if (headings.length === 0) {
    toc.style.display = 'none';
    return;
  }

  headings.forEach(function (h) {
    if (!h.id) {
      h.id = h.textContent.trim()
        .toLowerCase()
        .replace(/\s+/g, '-')
        .replace(/[^\w-]/g, '');
    }

    var li = document.createElement('li');

    if (h.tagName === 'H3') {
      var sub = tocList.querySelector('ul:last-child');
      if (!sub) {
        sub = document.createElement('ul');
        tocList.appendChild(sub);
      }
      sub.appendChild(li);
    } else {
      tocList.appendChild(li);
    }

    var a = document.createElement('a');
    a.href        = '#' + h.id;
    a.textContent = h.textContent;
    li.appendChild(a);
  });

  var links = Array.prototype.slice.call(tocList.querySelectorAll('a'));

  /* --- set active link --- */
  function setActive(h) {
    links.forEach(function (l) { l.classList.remove('active'); });
    var a = tocList.querySelector('a[href="#' + h.id + '"]');
    if (a) a.classList.add('active');
  }

  /* --- scroll-based active section (handles end-of-page correctly) --- */
  function updateActive() {
    var scrollY = window.scrollY || window.pageYOffset;
    var viewH   = window.innerHeight;
    var docH    = document.documentElement.scrollHeight;

    // at the very bottom → last heading wins
    if (scrollY + viewH >= docH - 5) {
      setActive(headings[headings.length - 1]);
      return;
    }

    var threshold = viewH * 0.25;
    var current   = null;

    headings.forEach(function (h) {
      if (h.getBoundingClientRect().top <= threshold) {
        current = h;
      }
    });

    if (current) setActive(current);
  }

  window.addEventListener('scroll', updateActive, { passive: true });
  updateActive();

  /* --- position TOC and align nav prompt above it --- */
  function positionToc() {
    if (window.innerWidth <= 900) return;
    var postEl = document.querySelector('.post-toc-wrapper > .post');
    if (!postEl) return;
    var postLeft  = postEl.getBoundingClientRect().left;
    var tocWidth  = toc.offsetWidth;
    var tocLeft   = Math.max(8, (postLeft - tocWidth) / 2);
    toc.style.left = tocLeft + 'px';

    /* center nav-prompt horizontally above the TOC */
    var navPrompt    = document.getElementById('nav-prompt');
    var navContainer = document.querySelector('.nav-container');
    if (navPrompt && navContainer) {
      var containerLeft = navContainer.getBoundingClientRect().left;
      var tocCenter     = tocLeft + tocWidth / 2;
      var promptWidth   = navPrompt.offsetWidth;
      navPrompt.style.marginLeft = Math.round(tocCenter - promptWidth / 2 - containerLeft) + 'px';
    }

    /* now that centering is done, start the typing animation (runs once) */
    if (window.__startNavTyping) window.__startNavTyping();
  }
  window.addEventListener('resize', positionToc);
  positionToc();

  /* --- smooth scroll + immediate active on click --- */
  links.forEach(function (link) {
    link.addEventListener('click', function (e) {
      var target = document.querySelector(this.getAttribute('href'));
      if (target) {
        e.preventDefault();
        links.forEach(function (l) { l.classList.remove('active'); });
        this.classList.add('active');
        target.scrollIntoView({ behavior: 'smooth' });
        toc.classList.remove('open');
      }
    });
  });

  /* --- mobile toggle --- */
  var menuBtn = document.getElementById('tocMenuBtn');
  if (menuBtn) {
    menuBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      toc.classList.toggle('open');
    });
    document.addEventListener('click', function (e) {
      if (window.innerWidth <= 900 && !toc.contains(e.target) && e.target !== menuBtn) {
        toc.classList.remove('open');
      }
    });
  }
}());
