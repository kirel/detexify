// requires canvassify, mathtran

$(function(){
    
  function train(tex, url) {
    $.post("http://localhost:4567/train", { "tex": tex, "url": url });
    c.clear
  }
  
  // Canvas
  var c = $("#tafel").get(0);
  var i = $("#info");
  i.text("Initialisiere Canvas...");
  canvassify(c);
  // Train if train button pressed
  $('#train').click(function(){
    train($('#tex').text(), c.toDataURL());
    clearCanvas(c);
    return false;
  });
  $('#clear').click(function(){
    clearCanvas(c);
    return false;
  });
  
  i.text("Bereit. Bitte malen!");
  mathtran.init();
});