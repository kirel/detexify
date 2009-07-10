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
        populateSymbolList(json.best);
        $('#morearea').show();
        latex.init();
        var setuptraining = function() {
          $('#symbols li .symbol img')
            .wrap('<a href="#"></a>')
            .tooltip({ tip: '#traintip' })
            .click(function(){
              $(this).tooltip(0).hide();
              $('#canvasspinner').show('scale');            
              train(this.alt.substring(7), canvas, function(){ $('#canvasspinner').hide('scale'); alert('Thanks!'); }); return false;
              });
        }
        setuptraining();
        // setup all list
        $('#more').unbind('click').click(function(){
          $('#morearea').hide();
          populateSymbolList(json.all);
          latex.init();
          setuptraining();
        });
        $('#hitarea').show();
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