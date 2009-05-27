// requires canvassify, mathtran

$(function(){
  // requests to classinatra
  $('#classinatra').text('Lade...');
  
  var abort;
    
  function classify(canvas) {
    abort = false;
    var url = canvas.toDataURL();
    $('#spinner').show();
    $.post("http://localhost:4567/classify", { "url": url }, function(json) {
      if (!abort) {
        $('#hitlist').empty();
        //$('#classinatra').text('Es wurde '+json.url+' angefordert.');
        jQuery.each( json.hits, function() {
          $('#spinner').hide();        
          $('#hitlist').append('<li><img alt="tex:'+this.tex+'"/> '+this.tex+' <span>Score: '+this.score+'</span></li>').show();
        });
        mathtran.init();
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