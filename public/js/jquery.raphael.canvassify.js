(function($) {
  
  function Point(x,y) {
    this.x = x;
    this.y = y;
    this.t = (new Date()).getTime();
  }
  
  function stroke2path(stroke) {
    var first = _.first(stroke);
    var path = _.map(_.rest(stroke), function(point) { return ["L", point.x, point.y]; })
    if (path.length == 0)
      return [["M", first.x, first.y], ["l", 0, 0.1]];
    else
      return [["M", first.x, first.y]].concat(path);
  }
  
  // canvassify object constructor -> new Canvassified(...) yields object
  Canvassified = function(container, config) {
    var canvassified = this;
    var defaults = {
      width: $(container).width(),
      height: $(container).height()
    }
    var config = $.extend({}, defaults, config);
    // code here...
    var paper = Raphael(container, config.width, config.height);
        
    var drawing = false;
    var current_stroke;
    var current_path;
    canvassified.strokes = [];
    
    var start = function (evt) {
      drawing = true;
      var x,y;
      x = evt.pageX - $(container).offset().left;
      y = evt.pageY - $(container).offset().top;

      current_stroke = [new Point(x,y)]; // initialize new stroke
      current_path = paper.path(stroke2path(current_stroke)).attr({'stroke-width': 5, 'stroke-linecap': 'round'});
    }
    var stroke = function(evt) {
      if (drawing) {
        var x,y;
        x = evt.pageX - $(this).offset().left;
        y = evt.pageY - $(this).offset().top;

        // console.log('pushing point at',x, y);
        
        current_stroke.push(new Point(x, y));
        current_path.attr('path', stroke2path(current_stroke));
      }
      // else {
      //   console.log('not drawing');
      // }
    }
    var stop = function(evt) {
      // console.log('stopping');
      // console.log(evt);
      if (drawing) {
        canvassified.strokes.push(current_stroke);
        if (config.callback) config.callback(canvassified.strokes);
        drawing = false;
      }
    }

    $(container).mousedown(start)
      .mousemove(stroke)
      .mouseup(stop)
      .mouseleave(stop);
    
    // maintainence functions
    canvassified.clear = function() {
      this.strokes = [];
      paper.clear();
    }
    
  }
  
  $.canvassify = function (container, config) {
    var container = $(container).get(0);
    return container.canvassified || (container.canvassified = new Canvassified(container, config));
  }
  
  $.fn.extend({
    canvassify: function(config) {
      $.canvassify(this, config);
      return this;
    }
  });
  
})(jQuery);