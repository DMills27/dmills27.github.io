document.addEventListener('DOMContentLoaded', function () {
  // Highlight all code blocks.
  // Skip pre.pandoc-highlight to preserve build-time <mark> tags.
  document.querySelectorAll('pre:not(.pandoc-highlight) > code')
    .forEach(function (block) {
      // Read the explicit language class BEFORE hljs modifies it.
      var lang = null;
      var langMatch = block.className.match(/\blanguage-(\S+)/);
      if (langMatch && langMatch[1] !== 'plaintext') {
        lang = langMatch[1];
      }

      hljs.highlightElement(block);

      // For blocks with no explicit language class, fall back to auto-detection.
      if (!lang && block.result && block.result.language) {
        lang = block.result.language;
      }

      // Append a language label to the <pre>.
      var pre = block.closest('pre');
      if (lang && pre) {
        var label       = document.createElement('span');
        label.className = 'code-lang-label';
        label.textContent = lang;
        pre.appendChild(label);
      }

      // Line numbers via the highlightjs-line-numbers plugin.
      if (typeof hljs.lineNumbersBlock === 'function') {
        hljs.lineNumbersBlock(block, { singleLine: true });
      }
    });
});
