// requires canvassify, mathtex

$(function(){
  // requests to classinatra  
  var abort, active, sentstrokes;
    
  function classify(canvas) {
    abort = false;
    if (active === 0) {
      $('#canvasspinner').show('scale');      
    }
    active = active + 1;
    sentstrokes = sentstrokes + 1;
    var sentstrokeswhencalled = sentstrokes;
    $.post("/classify", {"strokes": JSON.stringify(canvas.strokes) }, function(json) {
      if (!abort) {
        active = active - 1;
        if (active === 0) {
          $('#canvasspinner').hide('scale');
        }
        if (sentstrokeswhencalled < sentstrokes) return false;
        populateSymbolList(json.slice(0,5));
        $('#morearea').show();
        var setuptraining = function() {
          $('#symbols li .symbol img')
            .wrap('<a href="#"></a>')
            .tooltip({ tip: '#traintip' })
            .click(function(){
              $.gritter.add({title:'Thanks!', text:'Thank you for training!', time: 1000})
              $(this).tooltip(0).hide();
              $('#canvasspinner').show('scale');            
              train($(this).closest('li').attr('id'), canvas, function(json){
                // TODO DRY
                $('#canvasspinner').hide('scale');
                if (json.message) {
                  $.gritter.add({title:'Success!', text: json.message, time: 1000})
                } else {
                  $.gritter.add({title:'Error!', text: json.error, time: 1000})
                }
                });
              return false;
              });
        }
        setuptraining();
        // setup all list
        $('#more').unbind('click').click(function(){
          $('#morearea').hide();
          populateSymbolList(json);
          setuptraining();
          return false;
        });
        $('#hitarea').show();
      }
    }, 'json');
  }
  
  // Canvas
  var c = $("#tafel").get(0);
  canvassify(c, classify);
  active = 0;
  $('#clear').click(function(){
    abort = true;
    active = 0;
    sentstrokes = 0;
    c.clear();
    $('#hitarea').hide();
    $('#symbols').empty();
    $('#canvasspinner').hide();    
    return false;
  });
  $("#canvaserror").hide();
});