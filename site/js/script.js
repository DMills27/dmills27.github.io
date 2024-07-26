// ;(function(w, d) {
//   console.log('Hello, world!', w, d)
// })(window, document);

$(document).ready(function() {
  $("code[class^='language-']").each(function() {
    var $code = $(this);
    var numLines = $code.text().split(/\n/).length;
    var $numBox = $("<div/>").addClass("line-numbers");
    for (var i = 1; i <= numLines; i++) {
      $numBox.append($("<div/>").addClass("line-number").text(i));
    }
    $code.parent().prepend($numBox);
  });
});
