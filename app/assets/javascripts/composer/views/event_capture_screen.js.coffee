# Covers and capture mouse events for relay to interested objects.
class @Newstime.EventCaptureScreen extends Backbone.View

  events:
    'mousedown': 'mousedown'
    'mouseup': 'mouseup'
    'mousemove': 'mousemove'
    'click': 'click'

  initialize: (options) ->
    @$el.addClass "event-capture-screen"
    $('body').append(@el)

    # Apply top offset (Allows room for menu)
    @topOffset = options.topOffset
    @$el.css top: "#{@topOffset}px"


  mousedown: (e) ->
    e.stopPropagation()
    switch e.which
      when 1 # Left button
        @trigger 'mousedown', e

  #mouseup: (e) ->
    #e.stopPropagation()
    #@trigger 'mouseup', e

  mousemove: (e) ->
    e.stopPropagation()
    @trigger 'mousemove', e

  #click: (e) ->
    #e.stopPropagation()
    #@trigger 'click', e


  hideCursor: ->
    console.log "Hide Cursor"
    @$el.css
      cursor: 'none'

  showCursor: ->
    console.log "Show Cursor"
    @$el.css
      cursor: ''

  changeCursor: (cursor) ->
    @$el.css cursor: cursor
