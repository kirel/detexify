// requires canvassify, mathtran

$(function(){
  // requests to classinatra
  $('#classinatra').text('Lade...');
  
  var abort;
    
  function classify(canvas) {
    abort = false;
    var url = canvas.toDataURL();
    $('#spinner').show();
    alert(JSON.stringify(canvas.strokes));
    $.post("/classify", { "url": url, "fuck": "you", "strokes": JSON.stringify(canvas.strokes) }, function(json) {
      if (!abort) {
        $('#hitlist').empty();
        //$('#classinatra').text('Es wurde '+json.url+' angefordert.');
        jQuery.each( json.hits, function() {
          $('#spinner').hide();        
          $('#hitlist').append('<li>'+this.tex+' <img alt="tex:'+this.tex+'"/> <span>Score: '+this.score+'</span></li>').show();
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