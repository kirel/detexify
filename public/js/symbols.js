// requires canvassify, mathtex

$(function(){
  $('#spinner').show();  
  $.getJSON("/symbols", function(json) {
    json.sort(function(a,b){ return (''+a.command).localeCompare(''+b.command); })
    populateSymbolList(json);
    latex.init();
    // setup training
    $('#symbols li .symbol img')
      .wrap('<a href="#"></a>')
      .tooltip({ tip: '#traintip' })
      .click(function(){
        $(this).tooltip(0).hide();
        //$('#canvasspinner').show('scale');            
        //train(this.alt.substring(7), canvas, function(){ $('#canvasspinner').hide('scale'); alert('Thanks!'); }); return false;
        if ($('#trainingli').is(":hidden")) {
          $('#trainingli').insertAfter($(this).closest("li")).slideDown('slow');
        } else {
          var that = this;
          $('#trainingli').slideUp('slow', function(){
            $(this).insertAfter($(that).closest("li")).slideDown('slow');
          });
        }
        });
    
    // push the canvas inside the symbol list
    $('#trainingarea').appendTo('#symbols').wrap('<li id="trainingli"></li>').show();
    $('#spinner').hide();
    });

  });