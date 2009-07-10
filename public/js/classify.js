// requires canvassify, mathtex

$(function(){
  // requests to classinatra  
  var abort;
    
  function classify(canvas) {
    abort = false;
    var url = canvas.toDataURL();
    $('#canvasspinner').show('scale');
    $.post("/classify", { "url": url, "strokes": JSON.stringify(canvas.strokes) }, function(json) {
      if (!abort) {
        $('#canvasspinner').hide('scale');    
        $('#symbols').empty();
        populateSymbolList(json.all);
        $('#symbols li .symbol img')
          .wrap('<a href="#"></a>')
          .tooltip({ tip: '#traintip' })
          .click(function(){
            $(this).tooltip(0).hide();
            $('#canvasspinner').show('scale');            
            train(this.alt.substring(7), canvas, function(){ $('#canvasspinner').hide('scale'); alert('Thanks!'); }); return false;
            });
//      $('#morearea').show();
        latex.init();
        $('#hitarea').show();
        // setup all list
//        $('#more a').unbind('click').click(function(){
//          $('#more').hide();
//          $('#hitlist').empty();
//          jQuery.each( json.all, function() {
//            $('#hitlist').append('<tr class="tiptrigger"><td><code>'+this.tex+'</code></td><td class="symbol"><img alt="tex:'+this.tex+'"/></td><td class="score">'+this.score+'</td></tr>').show();
//          });          
//          setuptips();
//          mathtex.init();
//        });
      }
    }, 'json');
  }
  
  // Canvas
  var c = $("#tafel").get(0);
  canvassify(c, classify);
  $('#clear').click(function(){
    abort = true;
    c.clear();
    $('#hitarea').hide();
    $('#symbols').empty();
    $('#canvasspinner').hide();    
    return false;
  });
  $("#canvaserror").hide();
  latex.init();
});