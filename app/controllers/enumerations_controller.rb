# BetterMeans - Work 2.0
# Copyright (C) 2006  Shereef Bishay
#

class EnumerationsController < ApplicationController
  layout 'admin'
  
  before_filter :require_admin

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
  end

  def new
    begin
      @enumeration = params[:type].constantize.new
    rescue NameError
      @enumeration = Enumeration.new      
    end
  end

  def create
    @enumeration = Enumeration.new(params[:enumeration])
    @enumeration.type = params[:enumeration][:type]
    if @enumeration.save
      flash.now[:notice] = l(:notice_successful_create)
      redirect_to :action => 'list', :type => @enumeration.type
    else
      render :action => 'new'
    end
  end

  def edit
    @enumeration = Enumeration.find(params[:id])
  end

  def update
    @enumeration = Enumeration.find(params[:id])
    @enumeration.type = params[:enumeration][:type] if params[:enumeration][:type]
    if @enumeration.update_attributes(params[:enumeration])
      flash.now[:notice] = l(:notice_successful_update)
      redirect_to :action => 'list', :type => @enumeration.type
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @enumeration = Enumeration.find(params[:id])
    if !@enumeration.in_use?
      # No associated objects
      @enumeration.destroy
      redirect_to :action => 'index'
    elsif params[:reassign_to_id]
      if reassign_to = Enumeration.find_by_type_and_id(@enumeration.type, params[:reassign_to_id])
        @enumeration.destroy(reassign_to)
        redirect_to :action => 'index'
      end
    end
    @enumerations = Enumeration.find(:all, :conditions => ['type = (?)', @enumeration.type]) - [@enumeration]
  #rescue
  #  flash.now[:error] = 'Unable to delete enumeration'
  #  redirect_to :action => 'index'
  end
end
