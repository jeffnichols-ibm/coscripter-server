# (C) Copyright IBM Corp. 2010

require "base64"

class UtilsController < ApplicationController
  layout "browse"
  def index
    if request.post?
      instant_procedure = params[:procedure]
      @proc = JSON.pretty_unparse(instant_procedure)
      content = Base64.encode64(JSON.pretty_unparse(instant_procedure))
      title = instant_procedure[:title]|| "Script"
      @proc_link = "data:application/x-coscripter+json;base64,#{content}"
      @paste_code = "<a href=\"#{@proc_link}\">#{title}</a>"
    end
  end

end
