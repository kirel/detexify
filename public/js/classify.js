// requires canvassify, mathtex

$(function(){
  // requests to classinatra  
  var abort;
    
  function classify(canvas) {
    abort = false;
    var url = canvas.toDataURL();
    $('#spinner').show('scale');
    $.post("/classify", { "url": url, "strokes": JSON.stringify(canvas.strokes) }, function(json) {
      if (!abort) {
        $('#spinner').hide('scale');        
        $('#hitlist').empty();
        //$('#classinatra').text('Es wurde '+json.url+' angefordert.');
        jQuery.each( json.hits, function() {
          $('#hitlist').append('<tr><td><code>'+this.tex+'</code></td><td class="symbol"><img alt="tex:'+this.tex+'"/></td><td class="score">'+this.score+'</td></tr>').show();
        });
        mathtex.init();
        $('#hitarea').show();
      }
    }, 'json');
  }
  
  // Canvas
  var c = $("#tafel").get(0);
  $('#clear').click(function(){
    abort = true;
    c.clear();
    $('#hitarea').hide();
    $('#hitlist').empty();
    $('#spinner').hide();    
    return false;
  });
  canvassify(c, classify);
  $("#canvaserror").hide();
  mathtex.init();
});