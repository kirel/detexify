/**
 * tools.tooltip 1.0.2 - Tooltips done right.
 * 
 * Copyright (c) 2009 Tero Piirainen
 * http://flowplayer.org/tools/tooltip.html
 *
 * Dual licensed under MIT and GPL 2+ licenses
 * http://www.opensource.org/licenses
 *
 * Launch  : November 2008
 * Date: 2009-06-12 11:02:45 +0000 (Fri, 12 Jun 2009)
 * Revision: 1911 
 */
(function($) { 

	// static constructs
	$.tools = $.tools || {version: {}};
	
	$.tools.version.tooltip = '1.0.2';
	
	
	var effects = { 
		toggle: [
			function() { this.getTip().show(); },  
			function() { this.getTip().hide(); }
		],
		
		fade: [
			function() { this.getTip().fadeIn(this.getConf().fadeInSpeed); },  
			function() { this.getTip().fadeOut(this.getConf().fadeOutSpeed); } 
		]		
	};   
	
		
	$.tools.addTipEffect = function(name, loadFn, hideFn) {
		effects[name] = [loadFn, hideFn];	
	};
	
	
	/* this is how you add custom effects */
	
	/*
		default effect: "slideup", custom configuration variables: 
			- slideOffset
			- slideInSpeed
			- slideOutSpeed
	*/
	$.tools.addTipEffect("slideup", 
		
		function() { 
			var conf = this.getConf();
			var o = conf.slideOffset || 10;
			this.getTip().css({opacity:0}).animate({
				top: '-=' + o, 
				opacity:conf.opacity				
			}, conf.slideInSpeed || 200).show();                                            
		}, 
		
		function() {
			var conf = this.getConf();
			var o = conf.slideOffset || 10;
			this.getTip().animate({top: '-=' + o, opacity:0}, conf.slideOutSpeed || 200, function() { 
					$(this).hide().animate({top: '+=' + (o * 2)}, 0);
			});
		}
	);

	function Tooltip(trigger, conf) {
		
		var self = this;
		
		// find the tip
		var tip = trigger.next(); 
		
		if (conf.tip) {
			
			// single tip. ie: #tip
			if (conf.tip.indexOf("#") != -1) {
				tip = $(conf.tip);	
			
			} else {
				
				// find sibling
				tip = trigger.nextAll(conf.tip).eq(0);	
				
				// find sibling from the parent element
				if (!tip.length) {
					tip = trigger.parent().nextAll(conf.tip).eq(0);
				}
			} 
		} 
		
		// generic binding function
		function bind(name, fn) {
			$(self).bind(name, function(e, args)  {
				if (fn && fn.call(this) === false && args) {
					args.proceed = false;	
				}	
			});	
			
			return self;
		}
		
		// bind all callbacks from configuration
		$.each(conf, function(name, fn) {                   
			if ($.isFunction(fn)) { bind(name, fn); }
		}); 

		
		// mouse interaction 
		var isInput = trigger.is("input, textarea"); 
		trigger.bind(isInput ? "focus" : "mouseover", function(e) { 	 
			e.target = this;	
			self.show(e);  
			tip.hover(function() { self.show(); }, function() { self.hide(); }); 
		});
		
		trigger.bind(isInput ? "blur" : "mouseout", function() {
			self.hide(); 
		});

		tip.css("opacity", conf.opacity);		
		
		var timer = 0;
		
		$.extend(self, {
				
			show: function(e) {
				
				if (e) { trigger = $(e.target); }
				
				clearTimeout(timer);
				if (tip.is(":animated") || tip.is(":visible")) { return self; } 
				
				// onBeforeShow
				var p = {proceed: true};
				$(self).trigger("onBeforeShow", p);				
				if (!p.proceed) { return self; }

				
				
				/* calculate tip position */  
				 
				// vertical axis
				var top = trigger.position().top - tip.outerHeight();				
				var height = tip.outerHeight() + trigger.outerHeight();				
				var pos = conf.position[0];				
				if (pos == 'center') { top += height / 2; }
				if (pos == 'bottom') { top += height; }
				
				
				// horizontal axis
				var width = trigger.outerWidth() + tip.outerWidth();
				var left = trigger.position().left + trigger.outerWidth();									
				pos = conf.position[1];
				
				
				if (pos == 'center') { left -= width / 2; }
				if (pos == 'left')   { left -= width; }	
				
				// offset
				top += conf.offset[0];
				left += conf.offset[1];
				
				// set position
				tip.css({position:'absolute', top: top, left: left});

				
				effects[conf.effect][0].call(self);
				$(self).trigger("onShow");
				return self;
			},
			
			hide: function() {  
				clearTimeout(timer); 
				
				timer = setTimeout(function() {
					if (!tip.is(":visible")) { return self; }
					
					// onBeforeHide
					var p = {proceed: true};
					$(self).trigger("onBeforeHide", p);				
					if (!p.proceed) { return self; }

					
					effects[conf.effect][1].call(self); 
					$(self).trigger("onHide");
					
				}, conf.delay || 1);								 

				return self;
			},
			
			isShown: function() {
				return tip.is(":visible, :animated");	
			},
				
			getConf: function() {
				return conf;	
			},
				
			getTip: function() {
				return tip;	
			},
			
			getTrigger: function() {
				return trigger;	
			},
			
			// callback functions
			onBeforeShow: function(fn) {
				return bind("onBeforeShow", fn); 		
			},
			
			onShow: function(fn) {
				return bind("onShow", fn); 		
			},
			
			onBeforeHide: function(fn) {
				return bind("onBeforeHide", fn); 		
			},
			 
			onHide: function(fn) {
				return bind("onHide", fn); 		
			} 		

		});
		
	}
		
	
	// jQuery plugin implementation
	$.prototype.tooltip = function(conf) {
		
		// return existing instance
		var el = this.eq(typeof conf == 'number' ? conf : 0).data("tooltip");
		if (el) { return el; }
		
		// setup options
		var opts = { 

			/* 			
			- slideOffset
			- slideInSpeed
			- slideOutSpeed 
			*/	
			
			tip: null,
			effect: 'slideup',
			delay: 30,
			opacity: 1, 
			
			// 'top', 'bottom', 'right', 'left', 'center'
			position: ['top', 'center'], 
			offset: [0, 0], 
			api: false 
		};
		
		if ($.isFunction(conf)) {
			conf = {onBeforeShow: conf};
		}
		
		$.extend(opts, conf);
		
		// install tabs for each items in jQuery
		this.each(function() {
			el = new Tooltip($(this), opts);
			$(this).data("tooltip", el);	 
		});
		

		return opts.api ? el: this;		
		
	};
		
}) (jQuery);

		

