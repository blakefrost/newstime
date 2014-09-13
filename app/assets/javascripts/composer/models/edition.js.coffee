class @Newstime.Edition extends Backbone.RelationalModel
  urlRoot: '/editions/'
  idAttribute: '_id'

  relations: [{
    type: Backbone.HasMany
    key: 'sections'
    relatedModel: 'Newstime.Section'
    collectionType: 'Newstime.SectionCollection'
    keySource: 'sections_attributes'
    reverseRelation: {
      key: 'edition'
      includeInJSON: '_id'
    }
  }
  {
    type: Backbone.HasMany
    key: 'pages'
    relatedModel: 'Newstime.Page'
    collectionType: 'Newstime.PageCollection'
    keySource: 'pages_attributes'
    reverseRelation: {
      key: 'edition'
      includeInJSON: '_id'
    }
  }
  {
    type: Backbone.HasMany
    key: 'content_items'
    relatedModel: 'Newstime.ContentItem'
    collectionType: 'Newstime.ContentItemCollection'
    keySource: 'content_items_attributes'
    reverseRelation: {
      key: 'edition'
      includeInJSON: '_id'
    }
  }]

  initialize: (attributes, options) ->
    # Bind to change on collections for dirty tracking
    @get('sections').bind 'change', @change, this
    @get('pages').bind 'change', @change, this
    @get('content_items').bind 'change', @change, this

  change: ->
    @dirty = true

  save: ->
    success = super()
    if success
      @dirty = false

  isDirty: ->
    @dirty


class @Newstime.Section extends Backbone.RelationalModel


class @Newstime.SectionCollection extends Backbone.Collection
  model: Newstime.Section

class @Newstime.Page extends Backbone.RelationalModel


class @Newstime.PageCollection extends Backbone.Collection
  model: Newstime.Page
