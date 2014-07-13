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

    var dirtyClass = 'dirty';
    
    var start = function (evt) {
      $(container).addClass(dirtyClass);
      evt.preventDefault();
      if (evt.originalEvent) evt.originalEvent.preventDefault();
      evt.stopPropagation();
      drawing = true;
      var x,y;
      pageX = evt.originalEvent.touches ? evt.originalEvent.touches[0].pageX : evt.pageX
      pageY = evt.originalEvent.touches ? evt.originalEvent.touches[0].pageY : evt.pageY
      x = pageX - $(container).offset().left;
      y = pageY - $(container).offset().top;

      current_stroke = [new Point(x,y)]; // initialize new stroke
      current_path = paper.path(stroke2path(current_stroke)).attr({'stroke-width': 5, 'stroke-linecap': 'round'});
      return false;
    }
    var stroke = function(evt) {
      evt.preventDefault();
      if (evt.originalEvent) evt.originalEvent.preventDefault();
      evt.stopPropagation();
      if (drawing) {
        var x,y;
        pageX = evt.originalEvent.touches ? evt.originalEvent.touches[0].pageX : evt.pageX
        pageY = evt.originalEvent.touches ? evt.originalEvent.touches[0].pageY : evt.pageY
        x = pageX - $(this).offset().left;
        y = pageY - $(this).offset().top;

        // console.log('pushing point at',x, y);
        
        current_stroke.push(new Point(x, y));
        current_path.attr('path', stroke2path(current_stroke));
      }
      // else {
      //   console.log('not drawing');
      // }
      return false;
    }
    var stop = function(evt) {
      // console.log('stopping');
      // console.log(evt);
      evt.preventDefault();
      evt.stopPropagation();
      if (drawing) {
        canvassified.strokes.push(current_stroke);
        if (config.callback) config.callback(canvassified.strokes);
        drawing = false;
      }
      return false;
    }

    $(container).mousedown(start)
      .mousemove(stroke)
      .mouseup(stop)
      .mouseleave(stop)
      .on('touchstart', start).on('touchend touchleave touchcancel', stop).on('touchmove', stroke);

    // maintainence functions
    canvassified.clear = function() {
      $(container).removeClass(dirtyClass)
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
