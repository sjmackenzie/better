# BetterMeans - Work 2.0
# Copyright (C) 2006-2011  See readme for details and license#

class PersonalWelcome < ActiveRecord::Base
  belongs_to :user

  def self.deliver # spec_me cover_me heckle_me
    projects = Project.find(:all, :conditions => "created_at > '#{Time.now.advance :days => -7}' AND parent_id is null AND owner_id not in (select user_id from personal_welcomes)").group_by{|p| p.owner_id}

    projects.each_pair do |owner_id,project_list|
      project_list.sort! {|x,y| x.created_at <=> y.created_at }
      Mailer.send_later(:deliver_personal_welcome,User.find(owner_id),Project.find(project_list[0].id))
      PersonalWelcome.create :user_id => owner_id
    end
  end
end
