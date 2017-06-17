#!/usr/bin/ruby
# -*- coding: utf-8 -*-
#
# VCS working tree information inspector
# Copyright 2012 Hisashi Morita
# License: Public Domain
#
# Usage: vcsinfo.rb [options] subcommand [dir]
#   subcommand:
#     branch  display branch
#     log     display history
#     ls      display versioned files
#     rev     display revision
#   dir:
#     directory to inspect (default: .)
# Options:
#   --help    show help message
# Supported VCSs:
#   Git, Mercurial, Bazaar, and Subversion

require 'shellwords'

module VCSInfo
  VERSION = "0.0.1"
  class << self
    def cmd?(cmd)
      `which #{cmd.shellescape} >/dev/null`
      $?==0 ? true : false
    end

    def wt?(vcs, d)
      ds = d.shellescape
      case vcs
      when 'git' then e=`(cd #{ds} && git status --porcelain) 2>&1 >/dev/null`
      when 'hg'  then e=`(cd #{ds} && hg status) 2>&1 >/dev/null`
      when 'bzr' then e=`bzr status #{ds} 2>&1 >/dev/null`
      when 'svn' then e=`svn info #{ds} 2>&1 >/dev/null`
        # ignore SVN_ERR_WC_NOT_WORKING_COPY and warn otherwise
        unless /svn: (?:E155007)|(?:.*? is not a working copy)/m.match(e)
          $stderr.print(e)
        end
      else
        return false
      end
      $?==0 ? true : false
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

    def branch(d)
      ds = d.shellescape
      case guess_vcs(d)
      when :git
        `cd #{ds}; git rev-parse --abbrev-ref HEAD`.chomp
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
        `svn info #{ds} | grep '^URL' | xargs -I{} basename {}`.chomp
      else
        'unknown'
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
        `hg identify --id #{ds}`.chomp.gsub(/\+/, 'M')
      when :bzr
        rev_id = `bzr revno #{ds}`.chomp
        ifmod  = `bzr status --versioned #{ds}`.scan(/^\w+:/).empty? ? '' : 'M'
        rev_id + ifmod
      when :svn
        `svnversion #{ds}`.chomp.gsub(/:/, '-')
      else
        'unknown'
      end
    end
  end
end

if $0 == __FILE__
  require 'optparse'

  default_config = {
    :test => false
  }

  appfname = File.basename(__FILE__)
  clo = command_line_options = {}
  ARGV.options {|o|
    o.banner =<<-EOS.gsub(/^ {6}/, '')
      #{appfname}: VCS working tree information inspector

      Usage: #{appfname} [options] subcommand [dir]...

        subcommand:
              branch  display branch
              log     display log
              ls      display versioned files
              rev     display revision

        dir:
              directory to inspect (default: .)

      Options:
      EOS
    o.def_option('--help', 'show help message'){|s| puts o; exit}
    o.on_tail <<-EOS.gsub(/^ {6}/, '')

      Examples:
              #{appfname} branch            #=> master
              #{appfname} log > ChangeLog
              #{appfname} ls  > MANIFEST
              #{appfname} rev               #=> abc123, abc123M, etc.

      Supported VCSs:
              Git, Mercurial, Bazaar, and Subversion
      EOS
    o.parse!
  } or exit(1)

  if ARGV.empty?
    $stderr.print "#{appfname}: subcommand required\n"
    $stderr.print ARGV.options
    exit 1
  else
    unless [:branch, :log, :ls, :rev].include?(ARGV.first.intern)
      $stderr.print "#{appfname}: #{ARGV.first}: unsupported subcommand\n"
      $stderr.print ARGV.options
      exit 1
    else
      clo[:subcmd] = ARGV.first.intern
    end
  end
  if ARGV.size < 2
    clo[:workdirs] = ['.']
  else
    clo[:workdirs] = ARGV[1..-1]
  end

  config = default_config.update(clo)

  result = config[:workdirs].map{|wd|
    out = VCSInfo.send(config[:subcmd], wd)
    out ? out.chomp : nil
  }
  print result.join("\n")
  print "\n" if $stdout.tty?
end
