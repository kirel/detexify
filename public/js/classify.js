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
          $('#hitlist').append('<li><code>'+this.tex+'</code> : <span><img alt="tex:'+this.tex+'"/></span> <span>Score: '+this.score+'</span></li>').show();
        });
        mathtex.init();
      }
    }, 'json');
  }
  
  // Canvas
  var c = $("#tafel").get(0);
  var i = $("#info");
  $('#clear').click(function(){
    abort = true;
    clearCanvas(c);
    $('#hitlist').empty();
    $('#spinner').hide();    
    return false;
  });
  i.text("Initialisiere Canvas...");
  canvassify(c, classify);
  i.text("Bereit. Bitte malen!");
});