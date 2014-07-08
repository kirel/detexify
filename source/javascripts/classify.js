$(function(){
  // requests to classinatra
  var abort, active, sentstrokes;

  var latex_classifier = new Detexify({ baseuri: '/api/' });

  function positionUpLink() {
    $('#up').css({
      'position': 'fixed',
      'top'     : $(window).height()-$('#up').outerHeight()-20,
      'left'    : $('#hitarea').offset().left+540
    });
  }

  $(window).resize(positionUpLink);

  function classify(strokes) {
    abort = false;
    if (active === 0) {
      $('#canvasspinner').show('scale');
    }
    active = active + 1;
    sentstrokes = sentstrokes + 1;
    var sentstrokeswhencalled = sentstrokes;
    latex_classifier.classify(strokes, function(json) {
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
              latex_classifier.train($(this).closest('li').attr('id'), strokes, function(json){
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

        positionUpLink();

      }
    });
  }

  // Canvas
  var c = $.canvassify('#tafel', {callback: classify});
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
