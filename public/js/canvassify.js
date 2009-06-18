// make a canvas drawable and give the dataurl to some function after each stroke
// better canvas.drawable({start: startcallback, stop: stopcallback, stroke: strokecallback})
function canvassify(canvas, callback) {
  var ctx = canvas.getContext('2d');
  ctx.strokeStyle = "rgb(0, 0, 0)";
  ctx.lineWidth = 5;
  var draw = false;
  var current_stroke;
  canvas.strokes = [];
  var point = function(x,y) {
    return {"x":x, "y":y, "time": (new Date()).getTime()};
  }
  var start = function(evt) {
    draw = true;
    var x,y;
    x = evt.pageX - $(this).offset().left;
    y = evt.pageY - $(this).offset().top;
    ctx.fillRect(x-2, y-2, 5, 5);
    ctx.beginPath();
    ctx.moveTo(x, y);
    current_stroke = [point(x,y)]; // initialize new stroke
  }
  var stroke = function(evt) {
    if (draw) {
      var x,y;
      x = evt.pageX - $(this).offset().left;
      y = evt.pageY - $(this).offset().top;
      ctx.lineTo(x, y);
      ctx.stroke();
      current_stroke.push(point(x, y));
    }
  }
  var stop = function(evt) {
    if (draw) {
      canvas.strokes.push(current_stroke);
      if (callback) callback(canvas);
      draw = false;
    }
  }
  $(canvas).mousedown(start)
    .mousemove(stroke)
    .mouseup(stop)
    .mouseout(stop);
  return canvas;    
}

function clearCanvas(canvas) {
  canvas['strokes'] = [];
  var ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
}