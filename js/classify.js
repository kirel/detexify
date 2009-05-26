// requires canvassify, mathtran

$(function(){
  // requests to classinatra
  $('#classinatra').text('Lade...');
  
  function classify(canvas) {
    var url = canvas.toDataURL();
    $.post("http://localhost:4567/classify", { "url": url }, function(json) {
      $('#hitlist').empty();
      //$('#classinatra').text('Es wurde '+json.url+' angefordert.');
      jQuery.each( json.hits, function() {
        $('#hitlist').append('<li><img alt="tex:'+this.tex+'"/> '+this.tex+' <span>Score: '+this.score+'</span></li>');
      });
      mathtran.init();
    }, 'json');
  }
  
  // Canvas
  var c = $("#tafel").get(0);
  var i = $("#info");
  $('#clear').click(function(){
    clearCanvas(c);
    return false;
  });
  i.text("Initialisiere Canvas...");
  canvassify(c, classify);
  i.text("Bereit. Bitte malen!");
});