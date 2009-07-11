// Create a namespace, to hold variables and functions.
latex = new Object();

latex.assetHost = 'images/symbols/';

// Function to transform the whole document.  Add SRC to each IMG with
// ALT text starting with "tex:".  However, skip if element already
// has a SRC.
latex.init = function () {
  $('img').each(function() {
    if (this.alt.substring(0,7) == 'symbol:' && !this.src) {
      var id = this.alt.substring(7);
      // See http://xkr.us/articles/javascript/encode-compare/
      this.src = latex.assetHost + $.md5(id) + '.png';
      // Append TEX to the class of the IMG.
      //$(this).addClass('symbol');
    }
  });
}

function populateSymbolList(symbols) {
  $('#symbols').empty();
  jQuery.each(symbols, function() {
    var symbol;
    if (this.symbol) {
      symbol = this.symbol;
    } else {
      symbol = this;
    }
    var info = '';
    if (this.score) {
      info += '<span class="score">Score: '+this.score+'</span><br>';
    }
    if (symbol.package) {
      info += '<code class="package">\\usepackage{'+symbol.package+'}</code><br>';
    }
    if (symbol.fontenc) {
      info += '<code class="fontenc">\\usepackage['+symbol.fontenc+']{fontenc}</code><br>';
    }
    info += '<code class="command">'+symbol.command+'</code>';
    if (symbol.textmode && !symbol.mathmode) {
      info += '<br><span class="texmode">textmode</span>';
    }
    else if (symbol.mathmode && !symbol.textmode) {
      info += '<br><span class="texmode">mathmode</span>';
    }
    else if (symbol.textmode && symbol.mathmode) {
      info += '<br><span class="texmode">textmode & mathmode</span>';
    }
    if (symbol.samples != undefined) {
      info += '<br><span class="samples">Samples: <span class="number">'+symbol.samples+'</span></span><br>';
    }
    $('#symbols').append(
      '<li id="'+symbol.id+'"><div class="symbolsentry"><div class="symbol"><img alt="symbol:'+symbol.id+'"></div>'+
      '<div class="info">'+info+'</div></div></li>'
      );
  });
  latex.init();
}

// Train the symbol in canvas to id and call callback on return
function train(id, canvas, callback) {
  $.post("/train", { "id": id, "newtex": true, "url": canvas.toDataURL(), "strokes": JSON.stringify(canvas.strokes) }, callback);
}


$(function(){latex.init()});