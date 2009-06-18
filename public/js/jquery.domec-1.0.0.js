/**
 * jQuery DOMEC (DOM Elements Creator) 1.0.0
 * http://code.google.com/p/jquery-domec
 * http://plugins.jquery.com/project/DOMEC
 *
 * Copyright (c) 2008-2009 Lukasz Rajchel (lukasz@rajchel.pl | http://lukasz.rajchel.pl)
 * Dual licensed under the MIT (http://www.opensource.org/licenses/mit-license.php)
 * and GPL (http://www.opensource.org/licenses/gpl-license.php) licenses.
 *
 * Documentation	:	http://code.google.com/p/jquery-domec/wiki/Documentation
 * Changelog:		:	http://code.google.com/p/jquery-domec/wiki/Changelog
 */
 
/*global document, jQuery*/
(function ($) {
	$.domecCore = {
		// check if object is an array
		isArray: function (object) {
			return object !== null && typeof(object) === 'object' && 
				typeof(object.length) === 'number';
		},
		
		// create new element
		create: function (element, attributes, children, root) {

			// set default root if undefined
			if (root === undefined || root === null) {
				root = document;
			}

			// define variables
			var key, i, elem;
			
			//create new element
			if (typeof(element) === 'string') {
				elem = $(root.createElement(element));

				// add passed attributes
				if (typeof(attributes) === 'object' && !($.domecCore.isArray(attributes))) {
					for (key in attributes) {
						if (typeof(attributes[key]) === 'string') {
							elem.attr(key, attributes[key]);
						}
					}
				}
	
				// add passed child elements
				if (children !== undefined && children !== null) {
					// check if object is an array
					if ($.domecCore.isArray(children)) {
						for (i = 0; i < children.length; i += 1) {
							elem.append(children[i]);
						}
					} else {
						elem.text(children.toString());
					}
				}
			}

			return elem;
		}
	};

 	// register jQuery extension
	$.extend({
		create: $.domecCore.create
	});

})(jQuery);