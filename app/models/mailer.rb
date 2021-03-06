# BetterMeans - Work 2.0
# Copyright (C) 2006-2011  See readme for details and license#

class Mailer < ActionMailer::Base
  layout 'mailer'
  helper :application
  helper :issues

  include ActionController::UrlWriter
  include Redmine::I18n

  def self.default_url_options # spec_me cover_me heckle_me
    h = Setting.host_name
    h = h.to_s.gsub(%r{\/.*$}, '') unless Redmine::Utils.relative_url_root.blank?
    { :host => h, :protocol => Setting.protocol }
  end

  # Builds a tmail object used to email recipients of the added issue.
  #
  # Example:
  #   issue_add(issue) => tmail object
  #   Mailer.deliver_issue_add(issue) => sends an email to issue recipients
  def issue_add(issue) # spec_me cover_me heckle_me
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id issue
    recipient_list = issue.recipients
    recipient_list.delete issue.author.mail if issue.author.pref[:no_self_notified]
    recipients recipient_list
    cc(issue.watcher_recipients - @recipients)
    subject "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] (#{issue.status.name}) #{issue.subject}"
    body :issue => issue,
         :issue_url => url_for(:controller => 'projects', :action => 'dashboard', :show_issue_id => issue.id)
    render_multipart('issue_add', body)
  end

  # Builds a tmail object used to email recipients of the edited issue.
  #
  # Example:
  #   issue_edit(journal) => tmail object
  #   Mailer.deliver_issue_edit(journal) => sends an email to issue recipients
  def issue_edit(journal) # spec_me cover_me heckle_me
    issue = journal.journalized.reload
    redmine_headers 'Project' => issue.project.identifier,
                    'Issue-Id' => issue.id,
                    'Issue-Author' => issue.author.login
    redmine_headers 'Issue-Assignee' => issue.assigned_to.login if issue.assigned_to
    message_id journal
    references issue
    @author = journal.user
    recipient_list = issue.recipients
    recipient_list.delete @author.mail if @author.pref[:no_self_notified]
    recipients recipient_list
    # Watchers in cc
    cc(issue.watcher_recipients - @recipients)
    s = "[#{issue.project.name} - #{issue.tracker.name} ##{issue.id}] "
    s << "(#{issue.status.name}) " if journal.new_value_for('status_id')
    s << issue.subject
    subject s
    body :issue => issue,
         :journal => journal,
         :issue_url => url_for(:controller => 'projects', :action => 'dashboard', :show_issue_id => issue.id)

    render_multipart('issue_edit', body)
  end

  def daily_digest(recipient,journals) # spec_me cover_me heckle_me
    @journals = journals
    @author = User.sysadmin
    recipients recipient
    s = "Daily Digest - "
    s << Time.now.strftime("%m/%d/%Y")
    subject s
    body :journals => journals

    render_multipart('daily_digest', body)

  end

  def invitation_add(invitation,note) # spec_me cover_me heckle_me
    from invitation.user.mail
    subject "Invitation to join #{invitation.project.name}"
    recipients invitation.mail
    body :user => invitation.user,
         :project => invitation.project,
         :note => note,
         :invitation_url => url_for(:controller => :invitations, :action => "accept", :id => invitation.id, :token => invitation.token),
         :footer => Setting.emails_footer_nospam,
         :ignore_bcc_setting => true
    render_multipart('invitation_add', body)
    @ignore_bcc_setting = true
  end

  def invitation_remind(invitation,note) # spec_me cover_me heckle_me
    from invitation.user.mail
    subject "Reminder: Invitation to join #{invitation.project.name}"
    recipients invitation.mail
    body :user => invitation.user,
         :project => invitation.project,
         :note => note,
         :invitation_url => url_for(:controller => :invitations, :action => "accept", :id => invitation.id, :token => invitation.token),
         :footer => Setting.emails_footer_nospam,
         :ignore_bcc_setting => true
    render_multipart('invitation_remind', body)
    @ignore_bcc_setting = true
  end

  def reminder(user, issues, days) # spec_me cover_me heckle_me
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_reminder, issues.size)
    body :issues => issues,
         :days => days,
         :issues_url => url_for(:controller => 'issues', :action => 'index', :set_filter => 1, :assigned_to_id => user.id, :sort_key => 'due_date', :sort_order => 'asc')
    render_multipart('reminder', body)
  end

  # Builds a tmail object used to email users belonging to the added document's project.
  #
  # Example:
  #   document_added(document) => tmail object
  #   Mailer.deliver_document_added(document) => sends an email to the document's project recipients
  def document_added(document) # spec_me cover_me heckle_me
    redmine_headers 'Project' => document.project.identifier
    recipients document.recipients
    subject "[#{document.project.name}] #{l(:label_document_new)}: #{document.title}"
    body :document => document,
         :document_url => url_for(:controller => 'documents', :action => 'show', :id => document)
    render_multipart('document_added', body)
  end

  # Builds a tmail object used to email recipients of a project when an attachements are added.
  #
  # Example:
  #   attachments_added(attachments) => tmail object
  #   Mailer.deliver_attachments_added(attachments) => sends an email to the project's recipients
  def attachments_added(attachments) # spec_me cover_me heckle_me
    container = attachments.first.container
    added_to = ''
    added_to_url = ''
    case container.class.name
    when 'Project'
      added_to_url = url_for(:controller => 'projects', :action => 'list_files', :id => container)
      added_to = "#{l(:label_project)}: #{container}"
      recipients container.project.notified_users.select {|user| user.allowed_to?(:view_files, container.project) && !user.pref[:no_emails]}
    when 'Document'
      added_to_url = url_for(:controller => 'documents', :action => 'show', :id => container.id)
      added_to = "#{l(:label_document)}: #{container.title}"
      recipients container.recipients
    end
    redmine_headers 'Project' => container.project.identifier
    subject "[#{container.project.name}] #{l(:label_attachment_new)}"
    body :attachments => attachments,
         :added_to => added_to,
         :added_to_url => added_to_url
    render_multipart('attachments_added', body)
  end

  # Builds a tmail object used to email recipients of a news' project when a news item is added.
  #
  # Example:
  #   news_added(news) => tmail object
  #   Mailer.deliver_news_added(news) => sends an email to the news' project recipients
  def news_added(news) # spec_me cover_me heckle_me
    redmine_headers 'Project' => news.project.identifier
    message_id news
    recipients news.recipients
    subject "[#{news.project.name}] #{l(:label_news)}: #{news.title}"
    body :news => news,
         :news_url => url_for(:controller => 'news', :action => 'show', :id => news)
    render_multipart('news_added', body)
  end

  # Builds a tmail object used to email the recipients of the specified message that was posted.
  #
  # Example:
  #   message_posted(message) => tmail object
  #   Mailer.deliver_message_posted(message) => sends an email to the recipients
  def message_posted(message) # spec_me cover_me heckle_me
    redmine_headers 'Project' => message.project.identifier,
                    'Topic-Id' => (message.parent_id || message.id)
    message_id message
    references message.parent unless message.parent.nil?

    recipient_list = message.recipients
    recipient_list.delete message.author.mail if message.author.pref[:no_self_notified]
    recipients recipient_list


    all_recipients = (message.root.watcher_recipients + message.board.watcher_recipients).uniq - @recipients

    all_recipients.delete(message.author.mail) if message.author.pref[:no_self_notified] || message.author.pref[:no_emails]
    cc(all_recipients)

    subject "[#{message.board.project.name} - #{message.board.name} - msg#{message.root.id}] #{message.subject}"
    body :message => message,
         :message_url => url_for(:controller => 'messages', :action => 'show', :board_id => message.board_id, :id => message.root)
    render_multipart('message_posted', body)
  end

  # Builds a tmail object used to email the recipients of a project of the specified wiki content was added.
  #
  # Example:
  #   wiki_content_added(wiki_content) => tmail object
  #   Mailer.deliver_wiki_content_added(wiki_content) => sends an email to the project's recipients
  def wiki_content_added(wiki_content) # spec_me cover_me heckle_me
    redmine_headers 'Project' => wiki_content.project.identifier,
                    'Wiki-Page-Id' => wiki_content.page.id
    message_id wiki_content

    recipient_list = wiki_content.recipients
    recipient_list.delete wiki_content.author.mail if wiki_content.author.pref[:no_self_notified]
    recipients recipient_list

    cc(wiki_content.page.wiki.watcher_recipients - recipients)
    subject "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_added, :page => wiki_content.page.pretty_title)}"
    body :wiki_content => wiki_content,
         :wiki_content_url => url_for(:controller => 'wiki', :action => 'index', :id => wiki_content.project, :page => wiki_content.page.title)
    render_multipart('wiki_content_added', body)
  end

  # Builds a tmail object used to email the recipients of a project of the specified wiki content was updated.
  #
  # Example:
  #   wiki_content_updated(wiki_content) => tmail object
  #   Mailer.deliver_wiki_content_updated(wiki_content) => sends an email to the project's recipients
  def wiki_content_updated(wiki_content) # spec_me cover_me heckle_me
    redmine_headers 'Project' => wiki_content.project.identifier,
                    'Wiki-Page-Id' => wiki_content.page.id
    message_id wiki_content
    recipients wiki_content.recipients
    cc(wiki_content.page.wiki.watcher_recipients + wiki_content.page.watcher_recipients - recipients)
    subject "[#{wiki_content.project.name}] #{l(:mail_subject_wiki_content_updated, :page => wiki_content.page.pretty_title)}"
    body :wiki_content => wiki_content,
         :wiki_content_url => url_for(:controller => 'wiki', :action => 'index', :id => wiki_content.project, :page => wiki_content.page.title),
         :wiki_diff_url => url_for(:controller => 'wiki', :action => 'diff', :id => wiki_content.project, :page => wiki_content.page.title, :version => wiki_content.version)
    render_multipart('wiki_content_updated', body)
  end

  # Builds a tmail object used to email the specified user their account information.
  #
  # Example:
  #   account_information(user, password) => tmail object
  #   Mailer.deliver_account_information(user, password) => sends account information to the user
  def account_information(user, password) # spec_me cover_me heckle_me
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :password => password,
         :login_url => url_for(:controller => 'account', :action => 'login')
    render_multipart('account_information', body)
  end

  # Builds a tmail object used to email all active administrators of an account activation request.
  #
  # Example:
  #   account_activation_request(user) => tmail object
  #   Mailer.deliver_account_activation_request(user)=> sends an email to all active administrators
  def account_activation_request(user) # spec_me cover_me heckle_me
    # Send the email to all active administrators
    recipients User.active.find(:all, :conditions => {:admin => true}).collect { |u| u.mail }.compact
    subject l(:mail_subject_account_activation_request, Setting.app_title)
    body :user => user,
         :url => url_for(:controller => 'users', :action => 'index', :status => User::STATUS_REGISTERED, :sort_key => 'created_at', :sort_order => 'desc')
    render_multipart('account_activation_request', body)
  end

  # Builds a tmail object used to email the specified user that their account was activated by an administrator.
  #
  # Example:
  #   account_activated(user) => tmail object
  #   Mailer.deliver_account_activated(user) => sends an email to the registered user
  def account_activated(user) # spec_me cover_me heckle_me
    set_language_if_valid user.language
    recipients user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :user => user,
         :login_url => url_for(:controller => 'account', :action => 'login')
    render_multipart('account_activated', body)
  end

  def lost_password(token) # spec_me cover_me heckle_me
    set_language_if_valid(token.user.language)
    recipients token.user.mail
    subject l(:mail_subject_lost_password, Setting.app_title)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'lost_password', :token => token.value)
    render_multipart('lost_password', body)
  end

  def register(token) # spec_me cover_me heckle_me
    recipients token.user.mail
    subject l(:mail_subject_register, Setting.app_title)
    body :token => token,
         :url => url_for(:controller => 'account', :action => 'activate', :token => token.value)
    render_multipart('register', body)
  end

  # Builds a tmail object used to email recipients of the added issue.
  #
  # Example:
  #   issue_add(issue) => tmail object
  #   Mailer.deliver_issue_add(issue) => sends an email to issue recipients
  def personal_welcome(user,project) # spec_me cover_me heckle_me
    from "no-reply@better.boon.gl"
    recipients user.mail
    subject "bettermeans and " + project.name
    body :name => user.firstname,
        :footer => "Don't ask yourself what the world needs; ask yourself what makes you come alive and then go do that. Because what the world needs is people who are alive."
    render_multipart('personal_welcome', body)
  end


  def test(user) # spec_me cover_me heckle_me
    set_language_if_valid(user.language)
    recipients user.mail
    subject 'Bettermeans test'
    body :url => url_for(:controller => 'welcome')
    render_multipart('test', body)
  end

  # Overrides default deliver! method to prevent from sending an email
  # with no recipient, cc or bcc
  def deliver!(mail = @mail) # spec_me cover_me heckle_me
    return false if (recipients.nil? || recipients.empty?) &&
                    (cc.nil? || cc.empty?) &&
                    (bcc.nil? || bcc.empty?)

    # Set Message-Id and References
    if @message_id_object
      mail.message_id = self.class.message_id_for(@message_id_object)
    end
    if @references_objects
      mail.references = @references_objects.collect {|o| self.class.message_id_for(o)}
    end
    super(mail)
  end

  def email_update_activation(email_update) # spec_me cover_me heckle_me
    recipients email_update.mail
    subject l(:mail_subject_email_update_activation, Setting.app_title)
    body :activation_url => url_for(:controller => 'email_updates', :action => 'activate', :token => email_update.token)
    render_multipart('email_update_activation', body)
  end



  # Sends reminders to issue assignees
  # Available options:
  # * :days     => how many days in the future to remind about (defaults to 7)
  # * :tracker  => id of tracker for filtering issues (defaults to all trackers)
  # * :project  => id or identifier of project to process (defaults to all projects)
  def self.reminders(options={}) # spec_me cover_me heckle_me
    days = options[:days] || 7
    project = options[:project] ? Project.find(options[:project]) : nil
    tracker = options[:tracker] ? Tracker.find(options[:tracker]) : nil

    s = ARCondition.new ["#{IssueStatus.table_name}.is_closed = ? AND #{Issue.table_name}.due_date <= ?", false, days.day.from_now.to_date]
    s << "#{Issue.table_name}.assigned_to_id IS NOT NULL"
    s << "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}"
    s << "#{Issue.table_name}.project_id = #{project.id}" if project
    s << "#{Issue.table_name}.tracker_id = #{tracker.id}" if tracker

    issues_by_assignee = Issue.find(:all, :include => [:status, :assigned_to, :project, :tracker],
                                          :conditions => s.conditions
                                    ).group_by(&:assigned_to)
    issues_by_assignee.each do |assignee, issues|
      deliver_reminder(assignee, issues, days) unless assignee.nil?
    end
  end

  private

  def initialize_defaults(method_name) # cover_me heckle_me
    super
    set_language_if_valid Setting.default_language
    from Setting.mail_from

    # Common headers
    headers 'X-Mailer' => 'BetterMeans',
            'X-BetterMeans-Host' => Setting.host_name,
            'X-BetterMeans-Site' => Setting.app_title,
            'Precedence' => 'bulk',
            'Auto-Submitted' => 'auto-generated'
  end

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h) # cover_me heckle_me
    h.each { |k,v| headers["X-BetterMeans-#{k}"] = v }
  end

  # Overrides the create_mail method
  def create_mail # cover_me heckle_me
    # Removes the current user from the recipients and cc
    # if he doesn't want to receive notifications about what he does
    @author ||= User.current
    if @author.pref[:no_self_notified] || @author.pref[:no_emails]
      recipients.delete(@author.mail) if recipients
      cc.delete(@author.mail) if cc
      bcc.delete(@author.mail) if bcc
    end unless @author == User.anonymous #no need to check for prefs if current user is anonymous
    # Blind carbon copy recipients
    if Setting.bcc_recipients?
      bcc([recipients, cc].flatten.compact.uniq)
      recipients []
      cc []
    end unless @ignore_bcc_setting
    super
  end

  # Rails 2.3 has problems rendering implicit multipart messages with
  # layouts so this method will wrap an multipart messages with
  # explicit parts.
  #
  # https://rails.lighthouseapp.com/projects/8994/tickets/2338-actionmailer-mailer-views-and-content-type
  # https://rails.lighthouseapp.com/projects/8994/tickets/1799-actionmailer-doesnt-set-template_format-when-rendering-layouts

  def render_multipart(method_name, body) # cover_me heckle_me
    if Setting.plain_text_mail?
      content_type "text/plain"
      body render(:file => "#{method_name}.text.plain.html.erb", :body => body, :layout => 'mailer.text.plain.erb')
    else
      content_type "multipart/alternative"
      part :content_type => "text/plain", :body => render(:file => "#{method_name}.text.plain.html.erb", :body => body, :layout => 'mailer.text.plain.erb')
      part :content_type => "text/html", :body => render_message("#{method_name}.text.html.html.erb", body)
    end
  end

  # Makes partial rendering work with Rails 1.2 (retro-compatibility)
  def self.controller_path # cover_me heckle_me
    ''
  end unless respond_to?('controller_path')

  # Returns a predictable Message-Id for the given object
  def self.message_id_for(object) # cover_me heckle_me
    # id + timestamp should reduce the odds of a collision
    # as far as we don't send multiple emails for the same object
    timestamp = object.send(object.respond_to?(:created_at) ? :created_at : :updated_at)
    hash = "redmine.#{object.class.name.demodulize.underscore}-#{object.id}.#{timestamp.strftime("%Y%m%d%H%M%S")}"
    host = Setting.mail_from.to_s.gsub(%r{^.*@}, '')
    host = "#{::Socket.gethostname}.redmine" if host.empty?
    "<#{hash}@#{host}>"
  end

  def message_id(object) # cover_me heckle_me
    @message_id_object = object
  end

  def references(object) # cover_me heckle_me
    @references_objects ||= []
    @references_objects << object
  end

end

# Patch TMail so that message_id is not overwritten
module TMail

  class Mail

    def add_message_id( fqdn = nil ) # cover_me heckle_me
      self.message_id ||= ::TMail::new_message_id(fqdn)
    end

  end

end
