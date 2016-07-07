class WorkspacesController < ApplicationController
  skip_before_action :verify_authenticity_token

  respond_to :json

  def save_workspace
    @workspace = current_user.workspace
    @workspace.update_attributes workspace_params

    render json: @workspace
  end

private

  def workspace_params
    params.require(:workspace).permit(:color_palatte => [:top, :left, :width, :height],
                                      :pages_panel => [:top, :left, :width, :height])
  end

end
