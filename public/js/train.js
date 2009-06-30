// requires canvassify, mathtex

$(function(){

  function train(tex, canvas) {
    $.post("/train", { "tex": tex, "newtex": true, "url": canvas.toDataURL(), "strokes": JSON.stringify(canvas.strokes) }, function(json) {
      // receive new training string
      $('#trainingpattern code').text(json.tex);
      $('#trainingpattern #numsamples').text(json.samples);
      $('#trainingpattern img').attr('alt','tex:'+json.tex).removeAttr('src');
      mathtex.init(); // TODO make this better
      canvas.init();
      $('#spinner').hide('scale');
      $('#trainingpattern').effect('highlight');
      $('#trainpattern').click(trainclick); // FIXME awful names!
    }, 'json');
  }

  // Canvas
  var c = $("#tafel").get(0);
  canvassify(c);
  // Train if train button pressed
  var trainclick = function() { // FIXME auwful name
    $('#trainpattern').unbind('click', trainclick)
    $('#spinner').show('scale');
    // TODO Buttons ausgrauen solange Request $('...').ubind('click', fn);
    train($('#tex').text(), c);
    c.block();
    // TODO do this dynamically
    return false;
  }
  $('#trainpattern').click(trainclick);
  $('#clear').click(function(){
    c.clear();
    return false;
  });

  $("#canvaserror").hide();
  mathtex.init();
});