// requires canvassify, mathtex

$(function(){
  $('#spinner').show();  

  // Canvas
  var c = $("#tafel").get(0);
  canvassify(c);
  
  function colorcode(num) {
    var n = parseInt($(num).text());
    if (n < 26) {
      $(num).css('color','rgb('+(255-n*10)+','+(n*10)+',0)');
    } else {
      $(num).css('color','green');
    }    
  }

  $.getJSON("/symbols", function(json) {
    json.sort(function(a,b){ return (''+a.command).localeCompare(''+b.command); })
    populateSymbolList(json);
    latex.init();
    // color code training numbers
    var num = $('#symbols li .info .samples .number').each(function(){
      colorcode(this);
      });
    // setup training
    $('#symbols li .symbol img')
      .wrap('<a href="#"></a>')
      .tooltip({ tip: '#traintip' })
      .click(function(){
        $(this).tooltip(0).hide();
        if ($('#trainingli').is(":hidden")) {
          c.clear();
          $("#drawhere").show();
          $('#trainingli').prev().removeClass('active');
          $('#trainingli').insertAfter($(this).closest("li")).slideDown('slow');
          $('#trainingli').prev().addClass('active');
        } else {
          var that = this;
          $('#trainingli').prev().removeClass('active');
          $('#trainingli').slideUp('slow', function(){
            c.clear();
            $("#drawhere").show();
            $(this).insertAfter($(that).closest("li")).slideDown('slow');
            $('#trainingli').prev().addClass('active');
          });
        }
        return false;
        });
    
    // push the canvas inside the symbol list
    $('#trainingarea').appendTo('#symbols').wrap('<li id="trainingli"></li>').show();
    $('#spinner').hide();
    });

    // wire the canvas
      
  // Train if train button pressed
  var trainClicked = function() {
    // get the previous li's
    id = $(this).closest("li").prev().attr('id');
    num = $(this).closest("li").prev().find('.info .samples .number');
    $('#canvasspinner').show('scale');            
    train(id, c, function(){
      num.text(parseInt(num.text())+1);
      colorcode(num);
      $('#canvasspinner').hide('scale');
      alert('Thanks!');
      });
    // TODO Buttons ausgrauen solange Request $('...').ubind('click', fn);
    c.clear();
    // c.block();
    return false;
  }
  $('#train').click(trainClicked);
  $('#clear').click(function(){
    c.clear();
    return false;
  });
  $('#trainingarea').mouseenter(function(){$("#drawhere").fadeOut("slow");});

  $("#canvaserror").hide();  

  });