!function(e){function t(e,t){this.x=e,this.y=t,this.t=(new Date).getTime()}function a(e){var t=_.first(e),a=_.map(_.rest(e),function(e){return["L",e.x,e.y]});return 0==a.length?[["M",t.x,t.y],["l",0,.1]]:[["M",t.x,t.y]].concat(a)}Canvassified=function(n,o){var i,s,r=this,c={width:e(n).width(),height:e(n).height()},o=e.extend({},c,o),u=Raphael(n,o.width,o.height),h=!1;r.strokes=[];var p="dirty",f=function(o){e(n).addClass(p),o.preventDefault(),o.stopPropagation(),h=!0;var r,c;pageX=o.originalEvent.touches?o.originalEvent.touches[0].pageX:o.pageX,pageY=o.originalEvent.touches?o.originalEvent.touches[0].pageY:o.pageY,r=pageX-e(n).offset().left,c=pageY-e(n).offset().top,i=[new t(r,c)],s=u.path(a(i)).attr({"stroke-width":5,"stroke-linecap":"round"})},g=function(n){if(n.preventDefault(),n.stopPropagation(),h){var o,r;pageX=n.originalEvent.touches?n.originalEvent.touches[0].pageX:n.pageX,pageY=n.originalEvent.touches?n.originalEvent.touches[0].pageY:n.pageY,o=pageX-e(this).offset().left,r=pageY-e(this).offset().top,i.push(new t(o,r)),s.attr("path",a(i))}},v=function(e){e.preventDefault(),e.stopPropagation(),h&&(r.strokes.push(i),o.callback&&o.callback(r.strokes),h=!1)};e(n).mousedown(f).mousemove(g).mouseup(v).mouseleave(v).on("touchstart",f).on("touchend touchleave touchcancel",v).on("touchmove",g),r.clear=function(){e(n).removeClass(p),this.strokes=[],u.clear()}},e.canvassify=function(t,a){var t=e(t).get(0);return t.canvassified||(t.canvassified=new Canvassified(t,a))},e.fn.extend({canvassify:function(t){return e.canvassify(this,t),this}})}(jQuery);