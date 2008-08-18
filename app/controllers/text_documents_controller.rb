class TextDocumentsController < ApplicationController
	active_scaffold :text_document do |conf|
    conf.columns = [:name, :text]
  end
  def list
    redirect_to :controller => :protocols, :action => :list
  end
end
