# BetterMeans - Work 2.0
# Copyright (C) 2006-2011  See readme for details and license#

module MyHelper
  def describe(amount) # spec_me cover_me heckle_me
    amount == -1 ? 'unlimited' : amount
  end

  def my_issues_tabs # spec_me cover_me heckle_me
    tabs = [
            {:name => 'recent',
             :partial => 'issues/list_very_simple',
             :label => :label_recent_issues,
             :label_ending => " (#{@recent_issues.length})",
             :locals => {:issues => @recent_issues}
            },
            {:name => 'assigned',
             :partial => 'issues/list_very_simple',
             :label => :label_assigned_to_me_issues,
             :label_ending => " (#{@assigned_issues.length})",
             :locals => {:issues => @assigned_issues}
            },
            {:name => 'joined',
             :partial => 'issues/list_very_simple',
             :label => :label_joined_issues,
             :label_ending => " (#{@joined_issues.length})",
             :locals => {:issues => @joined_issues}
            },
            {:name => 'added',
             :partial => 'issues/list_very_simple',
             :label => :label_added_issues,
             :label_ending => " (#{@added_issues.length})",
             :locals => {:issues => @added_issues}
            },
            {:name => 'watched',
             :partial => 'issues/list_very_simple',
             :label => :label_watched_issues,
             :label_ending => " (#{@watched_issues.length})",
             :locals => {:issues => @watched_issues}
            }
          ]
  end


  def my_projects_tabs # spec_me cover_me heckle_me
    tabs = [
            {:name => 'all',
             :partial => 'my/project_list',
             :label => :label_projects_all,
             :locals => {
                          :my_projects => @all_projects,
                          :table_head => l(:label_projects_all),
                          :table_id => "all_my_projects_table",
                          :table_bottom_link => link_to(l(:label_project_new), {:controller => :projects, :action => :add}, :class => "gt-btn-blue-large"),
                          :no_data_help => l(:help_no_workstreams),
                          :no_data_link => link_to(l(:label_project_new), {:controller => 'projects', :action => 'add'}) + "<br>or<br>" + link_to(l(:label_browse_workstreams), {:controller => :projects, :action => :index})
                        }
            },
            {:name => 'active',
             :partial => 'my/project_list',
             :label => :label_projects_active_in,
             :locals => {
                          :my_projects => @active_projects,
                          :table_head => l(:label_projects_active_in),
                          :table_id => "active_projects_table",
                          :table_bottom_link => link_to(l(:label_browse_workstreams), {:controller => :projects, :action => :index}, :class => "gt-btn-blue-large"),
                          :no_data_help => l(:help_no_workstreams_active),
                          :no_data_link => link_to(l(:label_browse_workstreams), {:controller => :projects, :action => :index})
                        }
            },
            {:name => 'started',
             :partial => 'my/project_list',
             :label => :label_projects_i_started,
             :locals => {
                          :my_projects => @my_projects,
                          :table_head => l(:label_projects_i_started),
                          :table_id => "my_projects_table",
                          :table_bottom_link => link_to(l(:label_project_new), {:controller => :projects, :action => :add}, :class => "gt-btn-blue-large"),
                          :no_data_help => l(:help_no_my_workstreams),
                          :no_data_link => link_to(l(:label_project_new), {:controller => 'projects', :action => 'add'})
                        }
            },
          ]
  end


  def upgrade_options(user) # spec_me cover_me heckle_me
    if user.plan.code == Plan::FREE_CODE
      link_to "Upgrade", {:controller => :my, :action => :upgrade}, :class => "gt-btn-blue-large"
    else
      link_to "Upgrade / Downgrade", {:controller => :my, :action => :upgrade}, :class => "gt-btn-blue-large"
    end
  end
end
