# Redmine - project management software
# Copyright (C) 2006-2009  Shereef Bishay
#

require File.dirname(__FILE__) + '/../test_helper'

# Re-raise errors caught by the controller.
class SysController; def rescue_action(e) raise e end; end

class SysControllerTest < ActionController::TestCase
  fixtures :projects, :repositories
  
  def setup
    @controller = SysController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    Setting.sys_api_enabled = '1'
    Setting.enabled_scm = %w(Subversion Git)
  end
  
  def test_projects_with_repository_enabled
    get :projects
    assert_response :success
    assert_equal 'application/xml', @response.content_type
    with_options :tag => 'projects' do |test|
      test.assert_tag :children => { :count  => Project.active.has_module(:repository).count }
    end
  end

  def test_create_project_repository
    assert_nil Project.find(4).repository
    
    post :create_project_repository, :id => 4, 
                                     :vendor => 'Subversion',
                                     :repository => { :url => 'file:///create/project/repository/subproject2'}
    assert_response :created
    
    r = Project.find(4).repository
    assert r.is_a?(Repository::Subversion)
    assert_equal 'file:///create/project/repository/subproject2', r.url
  end
  
  def test_fetch_changesets
    get :fetch_changesets
    assert_response :success
  end
  
  def test_fetch_changesets_one_project
    get :fetch_changesets, :id => 'ecookbook'
    assert_response :success
  end
  
  def test_fetch_changesets_unknown_project
    get :fetch_changesets, :id => 'unknown'
    assert_response 404
  end
  
  def test_disabled_ws_should_respond_with_403_error
    with_settings :sys_api_enabled => '0' do
      get :projects
      assert_response 403
    end
  end
  
  def test_api_key
    with_settings :sys_api_key => 'my_secret_key' do
      get :projects, :key => 'my_secret_key'
      assert_response :success
    end
  end
  
  def test_wrong_key_should_respond_with_403_error
    with_settings :sys_api_enabled => 'my_secret_key' do
      get :projects, :key => 'wrong_key'
      assert_response 403
    end
  end
end
