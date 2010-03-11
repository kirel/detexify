function clippy_html(text, bgcolor) {
  if (!bgcolor) bgcolor = "#FFFFFF";
  return '<span id="clippy"> <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="110" height="14" id="clippy" > <param name="movie" value="/flash/clippy.swf"/> <param name="allowScriptAccess" value="always" /> <param name="quality" value="high" /> <param name="scale" value="noscale" /> <param NAME="FlashVars" value="text='+text+'"> <param name="bgcolor" value="'+bgcolor+'"> <embed src="/flash/clippy.swf" width="110" height="14" name="clippy" quality="high" allowScriptAccess="always" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" FlashVars="text='+text+'" bgcolor="'+bgcolor+'" /> </object> </span>';
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
    if (this.score || this.score === 0) {
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
    if (this.samples != undefined) {
      info += '<br><span class="samples">Samples: <span class="number">'+this.samples+'</span></span><br>';
    }
    $('#symbols').append(
      '<li id="'+symbol.id+'"><div class="symbolsentry"><div class="symbol"><img src="'+symbol.uri+'"></div>'+
      '<div class="info">'+info+'</div></div></li>'
    );
    if (this.score || this.score === 0) $('#symbols li:last').hover(function() {
      $('.info', this).append(clippy_html(symbol.command, '#F5F5F5'));
    }, function() {
      $("#clippy").remove();
    });
  });
}

// Train the symbol in canvas to id and call callback on return
function train(id, canvas, callback) {
  $.post("/train", { "id": id, "newtex": true, "strokes": JSON.stringify(canvas.strokes) }, callback, 'json');
}