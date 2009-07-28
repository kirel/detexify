// make a canvas drawable and give the stroke to some function after each stroke
// better canvas.drawable({start: startcallback, stop: stopcallback, stroke: strokecallback})
function canvassify(canvas, callback) {
  var ctx = canvas.getContext('2d');
  ctx.strokeStyle = "rgb(0, 0, 0)";
  ctx.lineWidth = 5;
  var draw = false;
  var current_stroke;
  canvas.strokes = [];
  var point = function(x,y) {
    return {"x":x, "y":y, "t": (new Date()).getTime()};
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
  // canvas addons
  canvas.clear = function() {
    canvas['strokes'] = [];
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  }
  canvas.init = function() {
    canvas.clear();
    $(canvas).mousedown(start)
      .mousemove(stroke)
      .mouseup(stop)
      .mouseout(stop);    
  }
  canvas.block = function() {
    canvas.clear();
    $(canvas).unbind();
  }
  canvas.init();
  return canvas;    
}