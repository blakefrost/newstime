class @Newstime.Section extends Backbone.RelationalModel

  # Section should maintain it's own collection of pages, that are specific to
  # it. The problem with this is keeping it in sync with the relationships
  # coming from the edition. Perhaps there is something we can do with backbone
  # relational.

  getPages: ->
    _.sortBy(@get('edition').get('pages').where(section_id: @get('_id')), 'number')

  getNextPageNumber: ->
    _.last(@getPages()).get('number') + 1

  addPage: ->
    pageAttributes =
      section_id: @get('_id')
      number: @getNextPageNumber()

    @get('edition').get('pages').create(pageAttributes)


class @Newstime.SectionCollection extends Backbone.Collection
  model: Newstime.Section

  url: ->
    "#{@edition.url()}/sections"