class @Newstime.Group extends Backbone.RelationalModel
  idAttribute: '_id'

  initialize: ->
    @bind 'change', @change

  change: ->
    #_.each @getContentItems(), (child) =>
      #child.set
        #top: @get('top') + child.get('group_offset_top')
        #left: @get('left') + child.get('group_offset_left')


  getContentItems: -> # TODO: Should be named getGroupedItems
    @_contentItems ?= @get('edition').get('content_items').where(group_id: @id)


  Object.defineProperties @prototype,
    top:
      get: -> @get('top')
      set: (value) ->
        @set 'top', value

    left:
      get: -> @get('left')
      set: (value) ->
        @set 'left', value

  # Gets page
  getPage: ->
    @_page ?= @get('edition').get('pages').findWhere(_id: @get('page_id'))

  setPage: (page) ->
    @_page = page
    @set 'page_id', page.get('_id')

class @Newstime.GroupCollection extends Backbone.Collection
  model: Newstime.Group
  url: ->
    "#{@edition.url()}/groups"
