#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#
# Miscllaneous utilities to get information inside VCS working tree
# Copyright 2012 Hisashi Morita
# License: Public Domain
#
# Usage:
#   vcswt.rb --log [WORKING_DIR] > ChangeLog
#   vcswt.rb --ls  [WORKING_DIR] > MANIFEST
#   vcswt.rb --rev [WORKING_DIR] #=> 123, 123M, etc

require 'shellwords'

module VCSWTUtils
  VERSION = "0.0.1"
  class App
    def cmd?(cmd)
      `which #{cmd.shellescape} >/dev/null`
      $?
    end

    def wt?(vcs, d)
      ds = d.shellescape
      case vcs
      when 'git' then `cd #{ds} && git status --porcelain >/dev/null 2>&1`
      when 'hg'  then `hg status #{ds} >/dev/null 2>&1`
      when 'bzr' then `bzr status #{ds} >/dev/null 2>&1`
      when 'svn' then `svn info #{ds} >/dev/null 2>&1`
      else
        false
      end
    end

    def guess_vcs(d)
      case
      when (cmd? 'git' and wt?('git', d)) then :git
      when (cmd? 'hg'  and wt?('hg',  d)) then :hg
      when (cmd? 'bzr' and wt?('bzr', d)) then :bzr
      when (cmd? 'svn' and wt?('svn', d)) then :svn
      else
        nil
      end
    end

    def log(d)
      ds = d.shellescape
      case guess_vcs(d)
      when :git then `cd #{ds}; git --no-pager log \
                      --format=\"%ai %aN %n%n%x09* %s%n\"`
      when :hg  then `cd #{ds}; hg log --style changelog`
      when :bzr then `cd #{ds}; bzr log --gnu-changelog`
      when :svn then
        if cmd? 'svn2cl' then `cd #{ds}; svn2cl --stdout --include-rev`
        else                  `cd #{ds}; svn log -rBASE:0 -v`
        end
      else
        nil
      end
    end

    def ls(d)
      ds = d.shellescape
      case guess_vcs(d)
      when :git
        `cd #{ds} && git ls-files | sort`
      when :hg
        `cd #{ds} && hg status --all \
         | grep -v '^?' | cut -c3- | sort`
      when :bzr
        `cd #{ds} && \
         (bzr ls --versioned --recursive --kind file; \
          bzr ls --versioned --recursive --kind symlink) \
         | sort`
      when :svn
        `cd #{ds} && svn status --non-interactive -v . \
         | grep -v '^?' | cut -c10- | awk '{ print \$4 }' \
         | xargs -n 1 -I{} find {} -maxdepth 0 ! -type d \
         | sort`
      else
        nil
      end
    end

    def branch(d)
      ds = d.shellescape
      case guess_vcs(d)
      when :git
        `cd #{ds}; git rev-parse --abbrev-ref HEAD`
      when :hg
        named_branch = `cd #{ds}; hg branch`.chomp
        bookmark = `cd #{ds}; hg bookmarks | grep '^ \* '`.
          gsub(/^ \* ([^ ]+?) +?[^ ]*?$/, '\1').chomp
        [named_branch, bookmark].delete_if{|e|e.empty?}.join('-')
      when :bzr
        nick = `cd #{ds}; bzr heads | grep '^ *branch nick: '`.
            gsub(/^ *branch nick: ([^ ]+)$/, '\1').chomp
        nick
      when :svn
        `svn info | grep '^URL' | xargs -I{} basename {}`
      else
        nil
      end
    end

    def rev(d)
      ds = d.shellescape
      case guess_vcs(d)
      when :git
        rev_id = `(cd #{ds} && git describe --all --long)`.
                 chomp.gsub(/\A.*?-g([0-9a-z]+).*\Z/, '\1')
        ifmod  = `(cd "${WD}" && git status)`.
                 scan(/modified:|added:|deleted:/).empty? ? '' : 'M'
        rev_id + ifmod
      when :hg
        `hg identify --id #{ds}`.gsub(/\+/, 'M')
      when :bzr
        rev_id = `bzr revno #{ds}`.chomp
        ifmod  = `bzr status --versioned #{ds}`.scan(/^\w+:/).empty? ? '' : 'M'
        rev_id + ifmod
      when :svn
        `svnversion #{ds}`.gsub(/:/, '-')
      else
        nil
      end
    end

    def help(d)
      ARGV.options; exit(0)
    end
  end
end

if $0 == __FILE__
  require 'optparse'
  default_config = {
    :cmd  => :help,
    :test => false
  }
  clo = command_line_options = {}
  ARGV.options {|o|
    o.def_option('--log', 'display log')            {|s| clo[:cmd] = :log}
    o.def_option('--ls',  'display versioned files'){|s| clo[:cmd] = :ls}
    o.def_option('--branch', 'display branch')      {|s| clo[:cmd] = :branch}
    o.def_option('--rev', 'display revision')       {|s| clo[:cmd] = :rev}
    o.def_option('--help', 'show this message')     {|s| clo[:cmd] = :help}
    o.parse!
  } or exit(1)
  config = default_config.update(clo)
  result = VCSWTUtils::App.new.send(config[:cmd], (arg = ARGV.first || '.'))
  print result.chomp
  print "\n" if $stdout.tty?
end
