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
    //$.post("/train", { "tex": tex, "url": canvas.toDataURL(), "strokes": JSON.stringify(canvas.strokes) });
    post("/train", { "tex": tex, "url": canvas.toDataURL(), "strokes": JSON.stringify(canvas.strokes) });
    //c.clear
  }

  // Canvas
  var c = $("#tafel").get(0);
  var i = $("#canvasinfo");
  i.text("Initialisiere Canvas...");
  canvassify(c);
  // Train if train button pressed
  $('#trainpattern').click(function(){
    train($('#tex').text(), c);
    //clearCanvas(c);
    // TODO do this dynamically
    //window.location.reload();
    return false;
  });
  $('#clear').click(function(){
    clearCanvas(c);
    return false;
  });

  i.text("Bereit. Bitte malen!");
  mathtex.init();
});