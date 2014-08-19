@Newstime = @Newstime || {}

class @Newstime.Selection extends Backbone.View

  initialize: (options) ->
    @$el.addClass 'selection'

    # Add draw handles
    @$el.html """
      <div class="draw-handle top"></div>
      <div class="draw-handle bottom"></div>
      <div class="draw-handle right"></div>
      <div class="draw-handle left"></div>
      <div class="draw-handle top-left"></div>
      <div class="draw-handle bottom-left"></div>
      <div class="draw-handle top-right"></div>
      <div class="draw-handle bottom-right"></div>
    """

    @gridInit()

    @bind 'mousedown', @mousedown
    @bind 'mousemove', @mousemove
    @bind 'mouseup',   @mouseup


  # Sets up and compute grid steps
  gridInit: ->
    ## TODO: Get the offset to be on the grid steps
    columnWidth = 34
    gutterWidth = 16
    columns = 24

    ## Compute Left Steps
    firstStep = gutterWidth/2
    columnStep = columnWidth + gutterWidth
    @leftSteps = _(columns).times (i) ->
      columnStep * i + firstStep

    firstStep = columnWidth
    columnStep = columnWidth + gutterWidth
    @rightSteps = _(columns).times (i) ->
      columnStep * i + firstStep

  activate: ->
    @active = true
    @$el.addClass 'resizable'

  deactivate: ->
    @active = false
    @$el.removeClass 'resizable'

  beginSelection: (anchorX, anchorY) ->
    #@trackingSelection = true

    @activate()

    @anchorX = anchorX
    @anchorY = anchorY

    @$el.css
      left: @anchorX
      top: @anchorY


  width: ->
    parseInt(@$el.css('width'))

  height: ->
    parseInt(@$el.css('height'))

  x: ->
    parseInt(@$el.css('left'))

  y: ->
    parseInt(@$el.css('top'))

  geometry: ->
    x: @x()
    y: @y()
    width: @width()
    height: @height()

  # Detects a hit of the selection
  hit: (x, y) ->

    geometry = @geometry()

    ## Expand the geometry by buffer distance in each direction to extend
    ## clickable area.
    buffer = 4 # 2px
    geometry.x -= buffer
    geometry.y -= buffer
    geometry.width += buffer*2
    geometry.height += buffer*2

    ## Detect if corrds lie within the geometry
    if x >= geometry.x && x <= geometry.x + geometry.width
      if y >= geometry.y && y <= geometry.y + geometry.height
        return true

    return false

  mousedown: (e) ->
    x = e.x
    y = e.y

    geometry = @geometry()

    # If active, check against the drag handles
    if @active

      # top drag handle hit?
      if x >= geometry.x + geometry.width/2 - 8 && x <= geometry.x + geometry.width/2  + 8
        if y >= geometry.y - 8 && y <= geometry.y + 8
          @resizing = true
          @resizeMode = "top"
          @trigger 'tracking', this
          return false # Cancel event

      # top-left drag handle hit?
      if x >= geometry.x - 8 && x <= geometry.x + 8
        if y >= geometry.y - 8 && y <= geometry.y + 8
          @resizing = true
          @resizeMode = "top-left"
          @trigger 'tracking', this
          return false # Cancel event

      # top-right drag handle hit?
      if x >= geometry.x + geometry.width - 8 && x <= geometry.x + geometry.width + 8
        if y >= geometry.y - 8 && y <= geometry.y + 8
          @resizing = true
          @resizeMode = "top-right"
          @trigger 'tracking', this
          return false # Cancel event

      # bottom-left drag handle hit?
      if x >= geometry.x - 8 && x <= geometry.x + 8
        if y >= geometry.y + geometry.height - 8 && y <= geometry.y + geometry.height + 8
          @resizing = true
          @resizeMode = "bottom-left"
          @trigger 'tracking', this
          return false # Cancel event

      # bottom-right drag handle hit?
      if x >= geometry.x + geometry.width - 8 && x <= geometry.x + geometry.width + 8
        if y >= geometry.y + geometry.height - 8 && y <= geometry.y + geometry.height + 8
          @resizing = true
          @resizeMode = "bottom-right"
          @trigger 'tracking', this
          return false # Cancel event

    return true

  mousemove: (e) ->
    if @resizing
      if @resizeMode == 'top'
        @dragTop(e.x, e.y)

      if @resizeMode == 'top-left'
        @dragTopLeft(e.x, e.y)

      if @resizeMode == 'top-right'
        @dragTopRight(e.x, e.y)

      if @resizeMode == 'bottom-left'
        @dragBottomLeft(e.x, e.y)

      if @resizeMode == 'bottom-right'
        @dragBottomRight(e.x, e.y)

  snapToGridLeft: (value) ->
    @closest(value , @leftSteps)

  snapToGridRight: (value) ->
    @closest(value , @rightSteps)

  # Utility function
  closest: (goal, ary) ->
    closest = null
    $.each ary, (i, val) ->
      if closest == null || Math.abs(val - goal) < Math.abs(closest - goal)
        closest = val
    closest


  dragTop: (x, y) ->
    geometry = @geometry()
    @$el.css
      top: y
      height: geometry.y - y + geometry.height

  dragTopLeft: (x, y) ->
    geometry = @geometry()
    x = @snapToGridLeft(x)
    @$el.css
      left: x
      top: y
      width: geometry.x - x + geometry.width
      height: geometry.y - y + geometry.height

  dragTopRight: (x, y) ->
    geometry = @geometry()
    x = @snapToGridRight(x)
    @$el.css
      top: y
      width: x - geometry.x
      height: geometry.y - y + geometry.height

  dragBottomLeft: (x, y) ->
    geometry = @geometry()
    x = @snapToGridLeft(x)
    @$el.css
      left: x
      width: geometry.x - x + geometry.width
      height: y - geometry.y

  dragBottomRight: (x, y) ->
    geometry = @geometry()
    x = @snapToGridRight(x)
    @$el.css
      width: x - geometry.x
      height: y - geometry.y

  mouseup: (e) ->
    @trigger 'tracking-release', this
