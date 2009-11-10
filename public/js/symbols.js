// requires canvassify, mathtex

$(function(){
  $('#spinner').show();  

  // Canvas
  var c = $("#tafel").get(0);
  canvassify(c);
  
  var symbols;
  var filter = '';
  
  var localesort = function(a,b){ return (''+a).localeCompare(''+b); }
  var alphasort = function(a,b){ return localesort(a.command, b.command); }
  var packagesort = function(a,b){
    if (a.package === b.package) {
      return alphasort(a, b);
    } else {
      return localesort(a.package, b.package);
    }
  }
  var samplesort = function(a,b){ return (a.samples - b.samples); }
  
  function colorcode(num) {
    var n = parseInt($(num).text());
    if (n < 26) {
      $(num).css('color','rgb('+(255-n*10)+','+(n*10)+',0)');
    } else {
      $(num).css('color','green');
    }    
  }
  
  var filtered = function(symbols) {
    // only show dem with package or command matching filter
    if (filter === '') return symbols;
    return $.grep(symbols, function(symbol, index){
      return (symbol.package && symbol.package.match(filter)) || symbol.command.match(filter)
    });
  }
  
  var populateSymbolListWrapper = function(symbols) {
    // secure the trainingarea
    $('#trainingarea').appendTo($('#safespot'));
    populateSymbolList(filtered(symbols));
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
  }
  
  $.getJSON("/symbols", function(json) {
    json.sort(alphasort)
    symbols = json;
    populateSymbolListWrapper(symbols);
    $('#spinner').hide();
    $('#up').css({
      'position': 'fixed',
      'top'     : $(window).height()-$('#up').outerHeight()-10,
      'left'    : $('#everything').offset().left+560
      });
    
    });
    
  $('#sort').change(function(){
    switch ($(this).val()) {
      case 'alpha':
        symbols.sort(alphasort)
      break;
      case 'samples':
        symbols.sort(samplesort)
      break;
      case 'package':
        symbols.sort(packagesort)
      break;
    }
    populateSymbolListWrapper(symbols);
  });
  
  $('#filter').keyup(function(){
    filter = $(this).val();
    populateSymbolListWrapper(symbols);
  });
      
  // Train if train button pressed
  var trainClicked = function() {
    $.gritter.add({title:'Thanks!', text:'Thank you for training!', time: 1000})
    // get the previous li's
    id = $(this).closest("li").prev().attr('id');
    num = $(this).closest("li").prev().find('.info .samples .number');
    $('#canvasspinner').show('scale');            
    train(id, c, function(json){
      num.text(parseInt(num.text())+1);
      colorcode(num);
      $('#canvasspinner').hide('scale');
      // TODO DRY
      if (json.message) {
        $.gritter.add({title:'Success!', text: json.message, time: 1000});
      } else {
        $.gritter.add({title:'Error!', text: json.error, time: 1000});
      }
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