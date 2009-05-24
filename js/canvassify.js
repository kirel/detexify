// make a canvas drawable and give the dataurl to some function after each stroke
// better canvas.drawable({start: startcallback, stop: stopcallback, stroke: strokecallback})
function canvassify(canvas, callback) {
  var ctx = canvas.getContext('2d');
  ctx.strokeStyle = "rgb(0, 0, 0)";
  ctx.lineWidth = 5;
  var draw = false;
  var start = function(evt) {
    draw = true;
    var x,y;
    x = evt.pageX - $(this).offset().left;
    y = evt.pageY - $(this).offset().top;
    ctx.beginPath();
    ctx.moveTo(x, y);
  }
  var stroke = function(evt) {
    if (draw) {
      var x,y;
      x = evt.pageX - $(this).offset().left;
      y = evt.pageY - $(this).offset().top;
      ctx.lineTo(x, y);
      ctx.stroke();
    }
  }
  var stop = function(evt) {
    if (draw) {
      if (callback) callback(canvas);
      draw = false;
      //ctx.beginPath();
    }
  }
  $(canvas).mousedown(start)
    .mousemove(stroke)
    .mouseup(stop)
    .mouseout(stop);
  return canvas;    
}

function clearCanvas(canvas) {
  var ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
}