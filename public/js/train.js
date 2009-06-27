// requires canvassify, mathtex

$(function(){

  function post(url, values)
  {
    values = values || {};

    var form = $.create("form", {action: url, method: "POST"}); //, style: "display: none"});
    for (var property in values)
    {
      if (values.hasOwnProperty(property))
      {
        var value = values[property];
        if (value instanceof Array)
        {
          for (var i = 0, l = value.length; i < l; i++)
          {
            form.append(
              $.create("input", {type: "hidden",
                name: property,
                value: value[i]}
              )
            );
          }
        }
        else
        {
          form.append(
            $.create("input", {type: "hidden",
              name: property,
              value: value}
            )
          );
        }
      }
    }
    $(document.body).append(form);
    form.submit();
    form.remove();
  }

  function train(tex, canvas) {
    $.post("/train", { "tex": tex, "url": canvas.toDataURL(), "strokes": JSON.stringify(canvas.strokes) }, function(json) {
      // receive new training string
      $('#trainingpattern code').text(json.tex);
      $('#trainingpattern #numsamples').text(json.samples);
      $('#trainingpattern img').attr('alt','tex:'+json.tex).removeAttr('src');
      mathtex.init(); // TODO make this better
      canvas.init();
      $('#spinner').hide();
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
    $('#spinner').show();
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