// Copyright: (c) 2007 The Open University, Milton Keynes, UK
// License: GPL version 2 or (at your option) any later version.
// Author: Jonathan Fine <jfine@pytex.org>, <J.Fine@open.ac.uk>

// Javascript that uses MathTran to add images to your web page.

/* Typical use:
   ...
   <script type="text/javascript" src="/js/mathtran_img.js"></script>
   ...
   <p id="mathtran_img.error">Hidden unless init() fails.</p>
   ...

   <p>The equation of the unit circle <img alt="tex:x^2+y^2=1" /> and
   a related trignometric identity <img alt="tex:\sin^2\theta +
   \cos^2\theta = 1" />.  </p>

   ...  */

// $Source: /cvsroot/mathtran/client/www/js/mathtran_img.js,v $ 
// $Revision: 1.1 $

// Create a namespace, to hold variables and functions.
mathtran = new Object();

// Change this use a different MathTran server.
mathtran.imgSrc = "http://www.mathtran.org/cgi-bin/mathtran?";

// Function to transform the whole document.  Add SRC to each IMG with
// ALT text starting with "tex:".  However, skip if element already
// has a SRC.
mathtran.init = function () {
  $('img').each(function() {
    if (this.alt.substring(0,4) == 'tex:' && !this.src) {
      var tex_src = this.alt.substring(4);
      // See http://xkr.us/articles/javascript/encode-compare/
      this.src = mathtran.imgSrc + 'D=10;tex=' + encodeURIComponent(tex_src);
      // Append TEX to the class of the IMG.
      $(this).addClass('tex');
    }
  });
}
