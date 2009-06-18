// Create a namespace, to hold variables and functions.
mathtex = new Object();

// Change this use a different MathTex server.
mathtex.imgSrc = 'http://www.kirelabs.org/cgi-bin/mathtex.cgi?\\png\\dpi{500}';

// Function to transform the whole document.  Add SRC to each IMG with
// ALT text starting with "tex:".  However, skip if element already
// has a SRC.
mathtex.init = function () {
  $('img').each(function() {
    if (this.alt.substring(0,4) == 'tex:' && !this.src) {
      var tex_src = this.alt.substring(4);
      // See http://xkr.us/articles/javascript/encode-compare/
      this.src = mathtex.imgSrc + encodeURIComponent(tex_src);
      // Append TEX to the class of the IMG.
      $(this).addClass('tex');
    }
  });
}
