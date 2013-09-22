# BetterMeans - Work 2.0
# Copyright (C) 2006-2011  See readme for details and license#

module Redmine
  module Themes

    # Return an array of installed themes
    def self.themes # spec_me cover_me heckle_me
      @@installed_themes ||= scan_themes
    end

    # Rescan themes directory
    def self.rescan # spec_me cover_me heckle_me
      @@installed_themes = scan_themes
    end

    # Return theme for given id, or nil if it's not found
    def self.theme(id) # spec_me cover_me heckle_me
      themes.find {|t| t.id == id}
    end

    # Class used to represent a theme
    class Theme
      attr_reader :name, :dir, :stylesheets

      def initialize(path) # spec_me cover_me heckle_me
        @dir = File.basename(path)
        @name = @dir.humanize
        @stylesheets = Dir.glob("#{path}/stylesheets/*.css").collect {|f| File.basename(f).gsub(/\.css$/, '')}
      end

      # Directory name used as the theme id
      def id; dir end # spec_me cover_me heckle_me

      def <=>(theme) # spec_me cover_me heckle_me
        name <=> theme.name
      end
    end

    private

    def self.scan_themes # cover_me heckle_me
      dirs = Dir.glob("#{RAILS_ROOT}/public/themes/*").select do |f|
        # A theme should at least override application.css
        File.directory?(f) && File.exist?("#{f}/stylesheets/application.css")
      end
      dirs.collect {|dir| Theme.new(dir)}.sort
    end
  end
end

module ApplicationHelper
  def stylesheet_path(source) # cover_me heckle_me
    @current_theme ||= Redmine::Themes.theme(Setting.ui_theme)
    super((@current_theme && @current_theme.stylesheets.include?(source)) ?
      "/themes/#{@current_theme.dir}/stylesheets/#{source}" : source)
  end

  def path_to_stylesheet(source) # cover_me heckle_me
    stylesheet_path source
  end
end
