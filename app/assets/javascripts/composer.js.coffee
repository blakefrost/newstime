# ## Libraries
#= require lib/zepto
#= require lib/underscore
#= require lib/backbone
#= require lib/backbone-relational
#= require lib/backbone.authtokenadapter
#= require faye
#
# ## App
#= require newstime_util
#= require_tree ./composer/plugins
#= require_tree ./composer/models
#= require_tree ./composer/views
#= require_tree ./composer/functions

@Newstime = @Newstime or {}

class @Newstime.Composer extends Backbone.View

  initialize: (options) ->
    @edition = options.edition
    @section = options.section

    # Create application vent for aggregating events.
    @vent = _.extend({}, Backbone.Events)

    window.onbeforeunload = ->
      if @edition.isDirty()
        return "You have unsaved changes."

    @captureAuthenticityToken()

    # Capture Elements
    @$window = $(window)
    @$document = $(document)
    @$body = $('body')
    @canvas = $('.page')[0]

    ## Config
    @topOffset = 62 # px

    @toolbox = new Newstime.Toolbox

    # Create application layers
    @coverLayerView = new Newstime.CoverLayerView # TODO: Rename Capture Layer
      composer: this
      topOffset: @topOffset
    @$body.append(@coverLayerView.el)

    @menuLayerView = new Newstime.MenuLayerView
      composer: this
      topOffset: @topOffset
    @$body.append(@menuLayerView.el)

    @panelLayerView = new Newstime.PanelLayerView
      composer: this
      topOffset: @topOffset
    @$body.append(@panelLayerView.el)

    @canvasLayerView = new Newstime.CanvasLayerView
      el: @canvas
      composer: this
      topOffset: @topOffset
      edition: @edition
      toolbox: @toolbox
    @$body.append(@canvasLayerView.el)


    @hasFocus = true # By default, composer has focus

    @keyboardHandler = new Newstime.KeyboardHandler
      composer: this

    @verticalSnapLine = new Newstime.VerticalSnapLine()
    @canvasLayerView.$el.append @verticalSnapLine.el
    @verticalSnapLine.hide()

    #canvasDragView = new Newstime.CanvasDragView
      #composer: this

    #@KeyboardHandler.bind 'dragModeEngaged', ->
      #canvasDragView.engage()

    #@KeyboardHandler.bind 'dragModeDisengaged', ->
      #canvasDragView.disengage()

    #Newstime.Composer.composerKeyboardHandler = @composerKeyboardHandler

    #$(document).keypress(@keypress)
    #$(document).keyup(@keyup)


    #@eventEmitter = new Newstime.EventEmitter (Mouse events, Keyboard Events,
    #Scroll Events)

    #var composerModals = $(".composer-modal"),
    #contentRegionModal = $(".add-content-region"),
    #contentItemModal = $(".add-content-item").contentModal();


    #keyboard.pushFocus(textRegion) // example

    # Initialize Plugins
    $("#edition-toolbar").editionToolbar(composer: this)
    $("#section-nav").sectionNav()

    @coverLayerView.bind 'mouseup', @mouseup, this
    @coverLayerView.bind 'mousemove', @mousemove, this
    @coverLayerView.bind 'mousedown', @mousedown, this
    @coverLayerView.bind 'contextmenu', @contextmenu, this
    @coverLayerView.bind 'dblclick', @dblclick, this

    @canvasLayerView.bind 'tracking',         @tracking, this
    @canvasLayerView.bind 'tracking-release', @trackingRelease, this
    @canvasLayerView.bind 'focus',            @handleLayerFocus, this

    @panelLayerView.bind 'tracking',         @tracking, this
    @panelLayerView.bind 'tracking-release', @trackingRelease, this

    @vent.on "edit-text", @editText, this

    #$("[headline-control]").headlineControl headlineProperties
    #storyPropertiesView = new Newstime.StoryPropertiesView()
    #$("[story-text-control]").each (i, el) ->
      #new Newstime.StoryTextControlView(
        #el: el
        #toolPalette: storyPropertiesView
      #)
      #return

    #contentRegionPropertiesView = new Newstime.ContentRegionPropertiesView()
    #$("[content-region-control]").each (i, el) ->
      #new Newstime.ContentRegionControlView(
        #el: el
        #propertiesView: contentRegionPropertiesView
      #)
      #return

    #photoPropertiesView = new Newstime.PhotoPropertiesView()
    #$("[photo-control]").each (i, el) ->
      #new Newstime.PhotoControlView(
        #el: el
        #propertiesView: photoPropertiesView
      #)
      #return

    #@gridOverlay = $(".grid-overlay").hide()

    ## Init panels
    @toolboxView = new Newstime.ToolboxView
      composer: this
      model: @toolbox
    @panelLayerView.attachPanel(@toolboxView)

    #@toolbox.bind 'change:selectedTool', @selectedToolChanged, this

    # Select default tool
    @toolbox.set(selectedTool: 'select-tool')

    @toolboxView.show()

    @propertiesPanelView = new Newstime.PropertiesPanelView
      composer: this

    @propertiesPanelView.setPosition(50, 20)
    @panelLayerView.attachPanel(@propertiesPanelView)
    @propertiesPanelView.show()

    @repositionScroll()

    @cursorStack = []

    @$window.resize => @windowResize()

    # Events
    #$(window).scroll(@captureScrollPosition)
    #
    #
    #
    $(document).on "paste", @paste

    @textEditor = new Newstime.TextAreaEditorView()
    @$body.append(@textEditor.el)


  editText: (model) ->
    @textEditor.show()
    #console.log this
    #Newstime.Composer.textEditor.show()
    # Display Text Area Editor
    # Attach model
    # Copy over values into a local model for the editor.
    # When they exit, save changes back to model, which will update view.

  windowResize: ->
    @canvasLayerView.trigger 'windowResize'

  # Focus on composer
  focus: ->
    $(document.activeElement).blur()
    @hasFocus = true

  blur: ->
    @hasFocus = false

  handleLayerFocus: (layer) =>
    @focusedLayer = layer

  # Called when keydown and composer hasFocus
  keydown: (e) =>
    if @focusedLayer
      @focusedLayer.trigger 'keydown', e

    unless e.isPropagationStopped()
      switch e.keyCode
        when 83 # s
          if e.ctrlKey || e.altKey # ctrl+s
            @edition.save() # Save edition

  paste: (e) =>
    if @focusedLayer
      @focusedLayer.trigger 'paste', e

  displayContextMenu: (contextMenu) ->
    @currentContextMenu = contextMenu

  selectedToolChanged: ->
    @updateCursor()

  tracking: (layer) ->
    @trackingLayer = layer

  trackingRelease: (layer) ->
    @trackingLayer = null


  captureAuthenticityToken: ->
    @authenticityToken = $("input[name=authenticity_token]").first().val()
    return

  toggleGridOverlay: ->
    @gridOverlay.toggle()
    return

  hideCursor: ->
    @coverLayerView.hideCursor()

  showCursor: ->
    @coverLayerView.showCursor()

  changeCursor: (cursor) ->
    @currentCursor = cursor
    @coverLayerView.changeCursor(@currentCursor)

  pushCursor: (cursor) ->
    @cursorStack.push @currentCursor
    @changeCursor(cursor)

  popCursor: ->
    cursor = @cursorStack.pop()
    @changeCursor(cursor)

  # Sets the UI cursor accoring to a set of rules.
  #updateCursor: ->
    #cursor = switch @toolbox.get('selectedTool')
      #when 'select-tool' then 'default'
      #when 'text-tool' then 'text'

    #@changeCursor(cursor)


  # Public: Handles mousemove events, called by CoverLayerView
  mousemove: (e) ->

    # Store current cursor location.
    @mouseX = e.x
    @mouseY = e.y

    # Compistae for top offset to allow room for menu
    #@mouseY -= @topOffset

    e =
      x: @mouseX
      y: @mouseY

    if @trackingLayer
      @trackingLayer.trigger 'mousemove', e
      return true

    hit = if @menuLayerView.hit(@mouseX, @mouseY)
      @menuLayerView
    else if @panelLayerView.hit(@mouseX, @mouseY)
      @panelLayerView
    else if @canvasLayerView.hit(@mouseX, @mouseY)
      @canvasLayerView

    if hit
      if @hitLayer != hit
        if @hitLayer
          @hitLayer.trigger 'mouseout', e
        @hitLayer = hit
        @hitLayer.trigger 'mouseover', e

    else
      if @hitLayer
        @hitLayer.trigger 'mouseout', e
        @hitLayer = null


    # Pass mousemove through to the hit layer
    if @hitLayer
      @hitLayer.trigger 'mousemove', e

      # Clear cursor state
      #@changeCursor('')


  mousedown: (event) ->
    @hasFocus = true
    e =
      x: @mouseX
      y: @mouseY
      button: event.button

    if @currentContextMenu
      @currentContextMenu.hide()
      @currentContextMenu = null

    if @trackingLayer
      # For the time being, block mousedowns while tracking
      return true

    # TODO: Rather than tracking an relying to the hovered object, we need to track
    # which if the layers gets the hit, and pass down to it for delegation to
    # the individual object.
    if @hitLayer
      @hitLayer.trigger 'mousedown', e

  dblclick: (event) ->
    e =
      x: @mouseX
      y: @mouseY
      button: event.button

    if @trackingLayer
      # For the time being, block dblclicks while tracking
      return true

    if @hitLayer
      @hitLayer.trigger 'dblclick', e


  contextmenu: (e) ->
    event = e
    e =
      x: @mouseX
      y: @mouseY
      preventDefault: ->
        event.preventDefault()

    if @hitLayer
      @hitLayer.trigger 'contextmenu', e


  mouseup: (e) ->

    e =
      x: @mouseX
      y: @mouseY

    if @trackingLayer
      @trackingLayer.trigger 'mouseup', e
      return true

    # TODO: Rather than tracking an relaying to the hovered object, we need to
    # track which of the layers gets the hit, and pass down to it for delegation
    # to the individual object.
    if @hitLayer
      @hitLayer.trigger 'mouseup', e

  zoomIn: ->
    @canvasLayerView.zoomIn()

  zoomOut: ->
    @canvasLayerView.zoomOut()

  zoomInPoint: (x, y) ->
    @canvasLayerView.zoomInPoint(x, y)

  zoomToPoint: (x, y) ->
    @canvasLayerView.zoomToPoint(x, y)

  zoomReset: ->
    @canvasLayerView.zoomReset()

  repositionScroll: ->
    @canvasLayerView.repositionScroll()

  # Adds a new page
  addPage: ->
    @section.addPage (page) =>
      @canvasLayerView.addPage(page)

  setSelection: (selection) ->
    @activeSelection.deactivate() if @activeSelection
    @activeSelection = selection

    # Update Properties Panel
    @updatePropertiesPanel(selection)


    # NOTE: This should be using a model, and the properties panel should be listening
    # for changes on the model

    #@trigger 'focus', this # Trigger focus event to get keyboard events

  clearSelection: () ->
    @activeSelection = null
    @propertiesPanelView.clear()

  updatePropertiesPanel: (target) ->
    propertiesView = target.getPropertiesView()
    @propertiesPanelView.mount(propertiesView)

  togglePanelLayer: ->
    @panelLayerView.toggle()

  # Sets toolbox tool
  #
  # Example:
  #
  #   @composer.setTool('select-tool')
  #
  setTool: (tool) ->
    @toolbox.set(selectedTool: tool)

  showVerticalSnapLine: (x) ->
    @verticalSnapLine.set(x)
    @verticalSnapLine.show()

  hideVerticalSnapLine: ->
    @verticalSnapLine.hide()


$ ->
  # Get the edition, mostly for development purposes right now.
  #edition_id = document.URL.match(/editions\/(\w*)/)[1] # Hack to get edition id from url string
  #window.edition = new Newstime.Edition({_id: edition_id})

  window.edition = new Newstime.Edition(editionJSON)
  window.edition.dirty = false # HACK: To make sure isn't considered dirty after initial creation

  # Global reference to current section model
  window.section =  edition.get('sections').findWhere(_id: composer.sectionID)

  Newstime.composer = new Newstime.Composer(edition: edition, section: section)
  window.composer   = Newstime.composer

  return
