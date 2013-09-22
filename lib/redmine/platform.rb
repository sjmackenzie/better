# Redmine - project management software
# Copyright (C) 2006-2011  See readme for details and license
#

module Redmine
  module Platform
    class << self
      def mswin? # spec_me cover_me heckle_me
        (RUBY_PLATFORM =~ /(:?mswin|mingw)/) || (RUBY_PLATFORM == 'java' && (ENV['OS'] || ENV['os']) =~ /windows/i)
      end
    end
  end
end
