class ContentItemsController < ApplicationController

  before_filter :authenticate_user!

  def index
    @content_items = Content::ContentItem.asc(:path)
  end

  def new
    @content_item = Content::ContentItem.new

    # Assign section if passed.
    @content_item.section = Section.find(params[:section_id]) if params[:section_id]
  end

  def create
     @content_region_id = params[:content_region_id] || content_item_params[:content_region_id]
    if @content_region_id
      # TODO: [security] User must have access to the section.
      @content_region = ContentRegion.find(@content_region_id)
    end

    @content_item = Content::ContentItem.new(content_item_params)

    if @content_region
      @content_region.content_items << @content_item
    end

    # Set content_item numbers
    @content_item.sequence = @content_region.next_content_item_sequence

    # All section must have an organization
    @content_item.organization = current_user.organization

    @content_item.save

    @content_region.resequence_content_items!

    #redirect_to :back, notice: "Content::ContentItem created successfully."
    redirect_to :back
  end

  def edit
    @content_item = Content::ContentItem.find(params[:id])
  end

  def show
    @content_item = Content::ContentItem.find(params[:id])
  end

  def update
    @content_item = Content::ContentItem.find(params[:id])
    if @content_item.update_attributes(content_item_params)
      redirect_to @content_item, notice: "Content::ContentItem updated successfully."
    else
      render "edit"
    end
  end

  # Returns an html form for creating a content item for consumption over ajax.
  #
  # Example request:
  #
  #   http://press.newstime.io/content_items/fields?type=Content::HeadlineContentItem
  #
  def form
    raise SecuityException unless [
      "Content::HeadlineContentItem",
      "Content::StoryTextContentItem",
      "Content::PhotoContentItem",
      "Content::VideoContentItem"
    ].include?(params[:type])
    @content_item = params[:type].camelize.constantize.new
    render layout: false
  end

private

  def content_item_params
    #params.require(:content_item).permit(:name, :section_id, :source, :layout_id)
    params.fetch(:content_item, {}).permit(:content_region_id, :_type, :text, :columns, :story_id, :caption)
  end

end