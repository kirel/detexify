/*
The Detexify object takes a base uri as it's argument and will prepend this to
the /train and /classify calls. The base uri is where the Detexify Sinatra app is mounted.
*/
function Detexify(config) {
  var classifier = this;
  classifier.config = $.extend({baseuri:"/"}, config);
  
  classifier.train = function(id, strokes, callback) {
    console.log(strokes);
    $.post(classifier.config.baseuri + "train", { "id": id, "strokes": JSON.stringify(strokes) }, callback, 'json');
  }
  classifier.classify = function(strokes, callback) {
    console.log(strokes);  
    $.post(classifier.config.baseuri + "classify", {"strokes": JSON.stringify(strokes) }, callback, 'json');
  }    
}