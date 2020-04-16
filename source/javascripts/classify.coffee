container = 'body'

workingIndicatorClass = 'classifying'
hitsIndicatorClass = 'classified'
updateWorkingIndicatorClass = (active) ->
  $(container).toggleClass(workingIndicatorClass, active > 0)

$ ->
  abort = false
  active = 0
  sentstrokes = 0
  latex_classifier = new Detexify(baseuri: "/api/")
  listElement = $('#classify--hit--list')

  classify = (strokes) ->
    abort = false
    active = active + 1
    updateWorkingIndicatorClass(active)
    sentstrokes = sentstrokes + 1
    sentstrokeswhencalled = sentstrokes
    latex_classifier.classify strokes, (json) ->
      unless abort
        active = active - 1
        updateWorkingIndicatorClass(active)
        return false if sentstrokeswhencalled < sentstrokes
        symbolsToShow = json.slice(0, 5)
        symbolsToRestrain = json.slice(5)
        populateSymbolList symbolsToShow, listElement
        $("#showmore").hide() unless symbolsToRestrain.length

        $("#showmore a").off("click").click (e) ->
          e.preventDefault()
          symbolsToShow = symbolsToShow.concat symbolsToRestrain.slice(0, 5)
          symbolsToRestrain = symbolsToRestrain.slice(5)
          $("#showmore").hide() unless symbolsToRestrain.length
          populateSymbolList symbolsToShow, listElement

        $(container).addClass(hitsIndicatorClass)
      return

    return

  $(".symbol-list").on "click", "li", ->
    command = $("code.command", this)[0]

    range = document.createRange()
    range.selectNode(command)

    selection = window.getSelection()
    selection.removeAllRanges()
    selection.addRange(range)

    try
      if document.execCommand("copy")
        selection.collapse(null) # Remove selection if copy succeeded

        $(this)
          .addClass "flash"
          .on "animationend", ->
            $(this).removeClass("flash")
    catch error
      console.error("Your browser doesn't support the copy command. Use CTRL + V instead.", error)

  # Canvas
  c = $.canvassify("#tafel",
    callback: classify
  )
  $("#clear").click (e) ->
    e.stopPropagation()
    e.preventDefault()
    abort = true
    active = 0
    updateWorkingIndicatorClass(active)
    sentstrokes = 0
    c.clear()
    $(container).removeClass(hitsIndicatorClass)
    $("#symbols").empty()

  $("#canvaserror").hide()
