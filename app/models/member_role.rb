# Redmine - project management software
# Copyright (C) 2006-2009  Shereef Bishay
#

class MemberRole < ActiveRecord::Base
  belongs_to :member
  belongs_to :role
  
  after_create :add_role_to_group_users
  after_create :remove_contributor_role_if_core

  after_destroy :remove_member_if_empty
  after_destroy :remove_role_from_group_users
  after_destroy :add_contributor_role_if_core
  
  validates_presence_of :role
  
  def validate
    errors.add :role_id, :invalid if role && !role.member?
  end
  
  private
  
  def remove_member_if_empty
    if member.roles.empty?
      member.destroy
    end unless role_id == Role::BUILTIN_CORE_MEMBER #We don't destory the member if the role being removed is the core_member role since we're going to add a contributor role    
  end
  
  def add_role_to_group_users
    if member.principal.is_a?(Group)
      member.principal.users.each do |user|
        user_member = Member.find_by_project_id_and_user_id(member.project_id, user.id) || Member.new(:project_id => member.project_id, :user_id => user.id)
        user_member.member_roles << MemberRole.new(:role => role, :inherited_from => id)
        user_member.save!
      end
    end 
  end
  
  def remove_role_from_group_users
    MemberRole.find(:all, :conditions => { :inherited_from => id }).each(&:destroy)
  end
  
  #Removes all contributor roles for this member if the current role being added is core
  def remove_contributor_role_if_core
    logger.info("removing contributor role : #{role_id}")
    MemberRole.find(:all, :conditions => {:member_id => member_id, :role_id => Role::BUILTIN_CONTRIBUTOR}).each(&:destroy) if role_id == Role::BUILTIN_CORE_MEMBER
  end
  
  #Adds contributor roles for this member if the current role being destroyed is core
  def add_contributor_role_if_core
    logger.info("Adding contributor role : #{role_id}")
    if role_id == Role::BUILTIN_CORE_MEMBER
      m = MemberRole.new :member_id => member_id, :role_id => Role::BUILTIN_CONTRIBUTOR 
      m.save
    end
  end
  
  
end
