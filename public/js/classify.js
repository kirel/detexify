// requires canvassify, mathtex

$(function(){
  // requests to classinatra  
  var abort;
  
  function train(tex, canvas) {
    $.post("/train", { "tex": tex, "url": canvas.toDataURL(), "strokes": JSON.stringify(canvas.strokes) }, function() {
      $('#spinner').hide('scale'); // TODO use different spinner   
      alert('Thanks for training!'); // TODO make this better
    });
  }
  
  function classify(canvas) {
    abort = false;
    var url = canvas.toDataURL();
    $('#spinner').show('scale');
    $.post("/classify", { "url": url, "strokes": JSON.stringify(canvas.strokes) }, function(json) {
      if (!abort) {
        $('#spinner').hide('scale');        
        $('#hitlist').empty();
        //$('#classinatra').text('Es wurde '+json.url+' angefordert.');
        jQuery.each( json.hits, function() {
          $('#hitlist').append('<tr class="tiptrigger"><td><code>'+this.tex+'</code></td><td class="symbol"><img alt="tex:'+this.tex+'"/></td><td class="score">'+this.score+'</td></tr>').show();
        });
        // now add tooltip behavior
        $('#hitlist .tiptrigger').tooltip(
          {
            tip: '#hittip', position: ['center', 'right'],
            delay: 0, effect: 'toggle', offset: [0,-100],
            onBeforeShow: function() {
              var trigger = this.getTrigger();
              $('a', this.getTip()).unbind('click').click(function(){
                $('#spinner').show('scale'); // TODO use different spinner   
                train($('code', trigger).text(), canvas);
              });
            }
          }
        );
        // and add training behavior
        // TODO
        mathtex.init();
        $('#hitarea').show();
      }
    }, 'json');
  }
  
  $("#chooselink").overlay();
  // Canvas
  var c = $("#tafel").get(0);
  $('#clear').click(function(){
    abort = true;
    c.clear();
    $('#hitarea').hide();
    $('#hitlist').empty();
    $('#spinner').hide();    
    return false;
  });
  canvassify(c, classify);
  $("#canvaserror").hide();
  mathtex.init();
});