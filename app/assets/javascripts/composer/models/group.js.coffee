class @Newstime.Group extends Backbone.RelationalModel
  idAttribute: '_id'

  initialize: ->
    @items = []
    #@bind 'change', @change
    @bind 'change:_id', @idSet

  Object.defineProperties @prototype,
    top:
      get: -> @get('top')
      set: (value) ->
        @set 'top', value

    left:
      get: -> @get('left')
      set: (value) ->
        @set 'left', value

  change: ->
    #_.each @getContentItems(), (child) =>
      #child.set
        #top: @get('top') + child.get('group_offset_top')
        #left: @get('left') + child.get('group_offset_left')

  idSet: ->
    _.each @items, (item) =>
      item.set 'group_id', @id

  getContentItems: -> # TODO: Should be named getGroupedItems
    @_contentItems ?= @get('edition').get('content_items').where(group_id: @id)

  addItems: (items) ->
    _.each items, @addItem

  addItem: (item) =>
    unless @isNew()
      item.set 'group_id', @id
    @items.push(item)

  removeItem: (item) =>
    # TODO: Could and probably should be using a collection here...
    index = @items.indexOf(item)
    @contentItemViewsArray.splice(index, 1)

  # Gets page
  getPage: ->
    @_page ?= @get('edition').get('pages').findWhere(_id: @get('page_id'))

  setPage: (page) ->
    @_page = page
    @set 'page_id', page.get('_id')

  # TODO: Shared code with content_item model, should create canvas item root.
  getBoundry: ->
    new Newstime.Boundry(@pick 'top', 'left', 'width', 'height')

  hit: ->
    boundry = @getBoundry()
    boundry.hit.apply(boundry, arguments)

class @Newstime.GroupCollection extends Backbone.Collection
  model: Newstime.Group
  url: ->
    "#{@edition.url()}/groups"
