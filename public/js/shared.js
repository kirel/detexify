function clippy_html(text, bgcolor) {
  if (!bgcolor) bgcolor = "#FFFFFF";
  return '<span id="clippy"> <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="110" height="14" id="clippy" > <param name="movie" value="/flash/clippy.swf"/> <param name="allowScriptAccess" value="always" /> <param name="quality" value="high" /> <param name="scale" value="noscale" /> <param NAME="FlashVars" value="text='+text+'"> <param name="bgcolor" value="'+bgcolor+'"> <embed src="/flash/clippy.swf" width="110" height="14" name="clippy" quality="high" allowScriptAccess="always" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer" FlashVars="text='+text+'" bgcolor="'+bgcolor+'" /> </object> </span>';
}

function populateSymbolList(symbols) {
  $('#symbols').empty();
      
  // prepare symbols for mustache
  var view = {symbols:_.map(symbols, function(symbol){
    $.extend(symbol, symbol.symbol);
    symbol.showscore = function() { return symbol.score != undefined }
    symbol.showsamples = function() { return symbol.samples != undefined }
    symbol.texmode = function() {
      if (symbol.textmode && !symbol.mathmode) {
        return "textmode";
      } else if (symbol.mathmode && !symbol.textmode) {
        return "mathmode"
      } else {
        return "textmode & mathmode"
      }
    }
    return symbol;
  })}
    
  var template = '{{#symbols}}' +
    '<li id="{{id}}"><div class="symbolsentry"><div class="symbol"><img src="{{uri}}"></div>'+
    '<div class="info">' +
    '{{#showscore}}<span class="score">Score: {{score}}</span><br>{{/showscore}}' +
    '{{#package}}<code class="package">\\usepackage{ {{package}} }</code><br>{{/package}}' +
    '{{#fontenc}}<code class="fontenc">\\usepackage[{{fontenc}}]{fontenc}</code><br>{{/fontenc}}' +
    '<code class="command">{{{command}}}</code>' +
    '<br><span class="texmode">{{texmode}}</span>' +
    //'{{#showsamples}}<br><span class="samples">Samples: <span class="number">{{samples}}</span></span><br>{{/showsamples}}' +
    '</div></div></li>' +
    '{{/symbols}}';
    
  $('#symbols').html($.mustache(template, view));
    
  $('#symbols li').hover(function() {
    $('.info', this).append(clippy_html(symbol.command, '#F5F5F5'));
  }, function() {
    $("#clippy").remove();
  });
}