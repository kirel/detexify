$ ->
  colorcode = (num) ->
    n = parseInt($(num).text())
    if n < 26
      $(num).css "color", "rgb(" + (255 - n * 10) + "," + (n * 10) + ",0)"
    else
      $(num).css "color", "green"
    return
  target = $("#symbols-list")
  symbols = []
  filter = ""
  latex_classifier = new Detexify(baseuri: "/api/")
  localesort = (a, b) ->
    ("" + a).localeCompare "" + b

  alphasort = (a, b) ->
    localesort a.command, b.command

  packagesort = (a, b) ->
    if a.package is b.package
      alphasort a, b
    else
      localesort a.package, b.package

  samplesort = (a, b) ->
    a.samples - b.samples

  filtered = (symbols) ->

    # only show dem with package or command matching filter
    return symbols  if filter is ""
    $.grep symbols, (symbol, index) ->
      (symbol.package and symbol.package.match(filter)) or symbol.command.match(filter)


  populateSymbolListWrapper = (symbols, target) ->
    populateSymbolList filtered(symbols), target
    return

  $("#sort").change ->
    switch $(this).val()
      when "alpha"
        symbols.sort alphasort
      when "samples"
        symbols.sort samplesort
      when "package"
        symbols.sort packagesort
    populateSymbolListWrapper symbols, target
    return

  jQuery.fn.handleKeyboardChange = (nDelay) ->

    # Utility function to test if a keyboard event should be ignored
    shouldIgnore = (event) ->
      mapIgnoredKeys =
        9: true # Tab
        16: true # Shift, Alt, Ctrl
        17: true
        18: true
        37: true # Arrows
        38: true
        39: true
        40: true
        91: true # Windows keys
        92: true
        93: true

      mapIgnoredKeys[event.which]
    
    # Utility function to fire OUR change event if the value was actually changed
    fireChange = ($element) ->
      unless $element.val() is jQuery.data($element[0], "valueLast")
        jQuery.data $element[0], "valueLast", $element.val()
        $element.trigger "change"
      return
    
    # The currently running timeout,
    # will be accessed with closures
    
    # Utility function to cancel a previously set timeout
    clearPreviousTimeout = ->
      clearTimeout timeout  if timeout
      return
    timeout = 0
    
    # User pressed a key, stop the timeout for now
    
    # Start a timeout to fire our event after some time of inactivity
    # Eventually cancel a previously running timeout
    @keydown((event) ->
      return  if shouldIgnore(event)
      clearPreviousTimeout()
      null
    ).keyup((event) ->
      return  if shouldIgnore(event)
      clearPreviousTimeout()
      $self = $(this)
      timeout = setTimeout(->
        fireChange $self
        return
      , nDelay)
      return
    ).change ->

      # Fire a change
      # Use our function instead of just firing the event
      # Because we want to check if value really changed since
      # our previous event.
      # This is for when the browser fires the change event
      # though we already fired the event because of the timeout
      fireChange $(this)

  $("#filter").handleKeyboardChange(300).change ->
    filter = $(this).val()
    populateSymbolListWrapper symbols, target
    return

  $.getJSON "/api/symbols", (json) ->
    $('#symbols--loading').hide()
    symbols = json
    symbols.sort alphasort
    populateSymbolListWrapper symbols, target

    #second time to make it work. This is an ugly workaround
    symbols.sort alphasort
    populateSymbolListWrapper symbols, target
