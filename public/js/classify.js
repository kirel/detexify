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
              $.gritter.add({title:'Thanks!', text:'Thank you for training!', time: 1000})
              $(this).tooltip(0).hide();
              $('#canvasspinner').show('scale');            
              train($(this).attr('alt').substring(7), canvas, function(){
                $('#canvasspinner').hide('scale');
                $.gritter.add({title:'Success!', text:'Sucessfully trained.', time: 1000});
                });
              return false;
              });
        }
        setuptraining();
        // setup all list
        $('#more').unbind('click').click(function(){
          $('#morearea').hide();
          populateSymbolList(json.all);
          latex.init();
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