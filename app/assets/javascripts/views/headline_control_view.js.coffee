@Newstime = @Newstime || {}

class @Newstime.HeadlineControlView extends Backbone.View

  events:
   'keydown .current-font-size': 'keydownFontSize'
   'change .nt-pick-font select': 'changeFont'

  keydownFontSize: (e) ->
    switch e.keyCode
      when 38 then delta = 1
      when 40 then delta = -1

    if delta
      fontSize = @$fontSizeInput.val()
      fontSize = "#{parseInt(fontSize)+delta}px"
      @$headline.css('font-size', fontSize)
      @$fontSizeInput.val(fontSize)

  changeFont: (e) ->
    @$headline.css 'font-family': $(e.currentTarget).val()

  initialize: ->
    @$el.addClass('headline-control')

    @$el.prepend """
      <div class="headline-tools">
        <div class='nt-pick-font'>
          <select>
            <option value=""></option>
            <option value="Exo">Exo</option>
          </select>
        </div>
        <div class="nt-adjust-size">
          <input class="current-font-size" value="48pt"></input>
        </div>
      </div>
    """


    @$headline = @$el.find('h1')
    @$fontSizeInput = @$el.find('.current-font-size')
