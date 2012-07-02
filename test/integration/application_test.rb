# BetterMeans - Work 2.0
# Copyright (C) 2006-2011  See readme for details and license
#

require "#{File.dirname(__FILE__)}/../test_helper"

class ApplicationTest < ActionController::IntegrationTest
  include Redmine::I18n

  fixtures :all

  def test_set_localization
    Setting.default_language = 'en'

    # a french user
    get 'projects', { }, 'Accept-Language' => 'fr,fr-fr;q=0.8,en-us;q=0.5,en;q=0.3'
    assert_response :success
    assert_tag :tag => 'h2', :content => 'Projets'
    assert_equal :fr, current_language

    # then an italien user
    get 'projects', { }, 'Accept-Language' => 'it;q=0.8,en-us;q=0.5,en;q=0.3'
    assert_response :success
    assert_tag :tag => 'h2', :content => 'Progetti'
    assert_equal :it, current_language

    # not a supported language: default language should be used
    get 'projects', { }, 'Accept-Language' => 'zz'
    assert_response :success
    assert_tag :tag => 'h2', :content => 'Workstreams'
  end

  def test_token_based_access_should_not_start_session
    # issue of a private project
    get 'issues/4.atom'
    assert_response 302

    rss_key = User.find(2).rss_key
    get "issues/4.atom?key=#{rss_key}"
    assert_response 200
    assert_nil session[:user_id]
  end
end
