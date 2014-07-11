@populateSymbolList = (symbols, target) ->
  $(target).empty()

  # prepare symbols for mustache
  view = symbols: _.map(symbols, (symbol) ->
    $.extend symbol, symbol.symbol
    symbol.showscore = ->
      symbol.score?

    symbol.showsamples = ->
      symbol.samples?

    symbol.texmode = ->
      if symbol.textmode and not symbol.mathmode
        "textmode"
      else if symbol.mathmode and not symbol.textmode
        "mathmode"
      else
        "textmode & mathmode"

    symbol
  )

  template = """
  {{#symbols}}
  <li id="{{id}}">
    <div class="symbol">
      <img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" class="{{css_class}}">
    </div>
    <div class="info">
      {{#showscore}}<span class="score">Score: {{score}}</span><br>{{/showscore}}
      {{#package}}<code class="package">\\usepackage{ {{package}} }</code><br>{{/package}}
      {{#fontenc}}<code class="fontenc">\\usepackage[{{fontenc}}]{fontenc}</code><br>{{/fontenc}}
      <code class="command">{{{command}}}</code><br>
      <span class="texmode">{{texmode}}</span>
    </div>
  </li>
  {{/symbols}}
  """

  $(target).html $.mustache(template, view)
