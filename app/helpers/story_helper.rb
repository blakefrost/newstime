require 'crawdad'
require 'crawdad/ffi'
require 'crawdad/ffi/tokens'
require 'crawdad/native'
require 'crawdad/html_tokenizer'
require 'stringio'

module StoryHelper

  def story_stream(story_name, width)
    @story_streams ||= {}
    @story_streams[story_name] ||= begin
      story = Story.get(story_name)
      elements = story.doc.css("body > *")
      LineStreamer.new(elements, width: width)
    end
  end

  def flow_story(story, options={})
    flow_text(story.body, options)
  end

  def flow_text(text, options={})
    width         = options[:width] || 284
    last_mod_time = options[:last_mod_time] || 284
		limit         = options[:limit] || 100

		html = $markdown.render(text)
    doc = Nokogiri::HTML(html)
		elements = doc.css("body > *")

		line_streamer = LineStreamer.new(elements, width: width)
		line_streamer.take(limit).html_safe
  end

  # Returns the current story fragment index for a given story name and verion
  # key. The version key can be used to have different tracks for the same story
  # in same document if needed.
  def story_fragment_index(story_name, version)
    @story_fragment_indexes ||= {}

    story_fragment_key = "#{story_name}-#{version}"
    index = @story_fragment_indexes[story_fragment_key]
    index = index ? index + 1 : 0
    @story_fragment_indexes[story_fragment_key] = index
  end

  def fetch_story_fragment(story_name, fragment_index, last_mod_time)
    fragment = $dalli.get "story_fragments/#{story_name}/#{fragment_index}"

    Rails.logger.info fragment && last_mod_time == fragment[:last_mod_time]
    Rails.logger.info last_mod_time
    #Rails.logger.info fragment[:last_mod_time]

    unless fragment && last_mod_time == fragment[:last_mod_time]
      Rails.logger.info "Typesetting Story: #{story_name}, Fragment Index: #{fragment_index}"
      fragment = {
        last_mod_time: last_mod_time,
        payload: yield
      }
      $dalli.set "story_fragments/#{story_name}/#{fragment_index}", fragment
    end

    fragment[:payload]
  end

  def story_html(story_name, options={})
    limit =  options[:limit]
    story = Story.get(story_name)
    story.html.html_safe
  end

  def lay_story(story_name, line_count, options={})
    width = options[:width] || 284
    tolorence = options[:tolerence] || 10

    limit =  options[:limit]
    story = Story.get(story_name)
    paragraphs = story.doc.css("body > p")
    paragraphs.map do |p|
      text = p.text

      stream = Crawdad::HtmlTokenizer.new(FontProfile2.get('minion')).paragraph(text, hyphenation: true, indent: 50)

      para = Crawdad::Paragraph.new(stream, :width => width)

      lines = para.lines(tolorence)
      stringio = StringIO.new
      lines.each do |tokens, breakpoint|
        stringio.write("<span class=\"line\">")

        # skip over glue and penalties at the beginning of each line
        tokens.shift until Crawdad::Tokens::Box === tokens.first

        tokens.each do |token|
          case token
          when Crawdad::Tokens::Box
            stringio.write(token.content)
          when Crawdad::Tokens::Glue
            stringio.write(" ")
          end
        end
        last_token = tokens.last
        if last_token.class == Crawdad::Tokens::Penalty && last_token[:flagged] == 1
          stringio.write("-")
        end
        stringio.write("</span> ")
      end
      "<p class=\"typeset\">#{stringio.string}</p>"
    end.join.html_safe
  end

end