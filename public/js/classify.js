// requires canvassify, mathtex

$(function(){
  // requests to classinatra
  $('#classinatra').text('Lade...');
  
  var abort;
    
  function classify(canvas) {
    abort = false;
    var url = canvas.toDataURL();
    $('#spinner').show();
    $.post("/classify", { "url": url, "strokes": JSON.stringify(canvas.strokes) }, function(json) {
      if (!abort) {
        $('#hitlist').empty();
        //$('#classinatra').text('Es wurde '+json.url+' angefordert.');
        jQuery.each( json.hits, function() {
          $('#spinner').hide();        
          $('#hitlist').append('<tr><td><code>'+this.tex+'</code></td><td class="symbol"><img alt="tex:'+this.tex+'"/></td><td class="score">'+this.score+'</td></tr>').show();
        });
        mathtex.init();
        $('#hitarea').show();
      }
    }, 'json');
  }
  
  // Canvas
  var c = $("#tafel").get(0);
  var i = $("#canvasinfo");
  $('#clear').click(function(){
    abort = true;
    clearCanvas(c);
    $('#hitarea').hide();
    $('#hitlist').empty();
    $('#spinner').hide();    
    return false;
  });
  i.text("Initialisiere Canvas...");
  canvassify(c, classify);
  i.text("Bereit. Bitte malen!");
});