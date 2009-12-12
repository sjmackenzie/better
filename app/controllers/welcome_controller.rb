# BetterMeans - Work 2.0
# Copyright (C) 2006  Shereef Bishay
#

class WelcomeController < ApplicationController
  caches_action :robots

  def index
    @news = News.latest User.current
    @projects = Project.latest User.current, 10, false
    @enterprises = Project.latest User.current, 10, true
  end
  
  def robots
    @projects = Project.all_public.active
    render :layout => false, :content_type => 'text/plain'
  end
end
