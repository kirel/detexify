// requires canvassify, mathtex

$(function(){
  $('#spinner').show();  
  $.getJSON("/symbols", function(json) {
    json.sort(function(a,b){ return (''+a.command).localeCompare(''+b.command); })
    populateSymbolList(json);
    $('#spinner').hide();
    });

  });