#!/usr/bin/env ruby
#
# hey! a minimalist CRM for http://todotxt.com/
#
# hey tells you one thing you should do regularly, but haven't done lately.
#
#   $ todo.sh lf hey
#   1 @phone Mom (+1 234 567 8901) +family
#   2 @skype Dad +family
#   3 @email mentor
#   4 @write old flame <hot@example.com>
#   --
#   HEY: 4 of 4 tasks shown
#
#   $ todo.sh hey
#   37 @phone Mom (+1 234 567 8901) +family
#   TODO: 37 added
#
# How To Install:
#
#   $ mkdir -p ~/.todo.actions.d/ && pushd ~/.todo.actions.d/
#   $ git clone git://gist.github.com/4241425.git hey.git
#   $ ln -s hey.git/hey.rb hey && popd
#   $ todo.sh addto hey.txt @phone Mom
#   $ todo.sh hey
#
# A New Definition of Regularly:
#
#   $ echo 'export HEY_CYCLE=30' >> ~/.todo.cfg
#
# Copyright 2012 Scott Robinson <sr@thoughtworks.com>
# Licensed under the Apache License, Version 2.0

require 'date'

module Todo
  class List < Array
    def initialize fn
      replace File.readlines(fn).map { |l| Task.new l }
    end
  end

  class Task < String
    DONE_REGEXP = /^x\s+/
    PRIORITY_REGEXP = /^\([A-Za-z]\)\s+/
    DATE_REGEXP = /
      # A date is either ...
      (?:
        ^ |                     # after the beginning of a line
        #{PRIORITY_REGEXP} |    # or, after a priority
        #{DONE_REGEXP}          # or, after a done mark
      )

      ([0-9]{4}-[0-9]{2}-[0-9]{2})\b/x
    CONTEXT_REGEXP = /(?:^|\s)@\w+\b/
    PROJECT_REGEXP= /(?:^|\s)\+\w+\b/

    def date
      @date ||= begin
                  if self =~ DATE_REGEXP
                    Date.parse $1
                  end
                end
    end

    def text
      @text ||= self.
        gsub(DONE_REGEXP, '').
        gsub(DATE_REGEXP, '').
        gsub(PRIORITY_REGEXP, '').
        gsub(CONTEXT_REGEXP, '').
        gsub(PROJECT_REGEXP, '').
        strip
    end
  end
end

cmd = ARGV.shift
if cmd == 'usage'
  puts <<-EOF
  Minimalist CRM:
    hey
    hey [TERM...]
      Adds one task, that hasn't been seen recently, from your hey.txt.
      (30 days reocurrence)
  EOF
  exit
end

['TODO_DIR', 'TODO_FILE', 'DONE_FILE'].each do |fn|
  raise "Hey! Where's your $#{fn}?" unless File.exist? ENV[fn].to_s
end

log = Todo::List.new(ENV['TODO_FILE']) + Todo::List.new(ENV['DONE_FILE'])

ENV['HEY_FILE'] ||= File.join ENV['TODO_DIR'], 'hey.txt'
todo = Todo::List.new ENV['HEY_FILE']
todo = todo.grep /#{ARGV.join ' '}/i unless ARGV.empty?

days = ENV['HEY_CYCLE'].to_i
days = 30 if days.zero?
cutoff = Date.today - days

done_or_scheduled = log.select { |t| (t.date || Date.today) > cutoff }.map &:text
new = todo.reject { |t| done_or_scheduled.include? t.text }

hey = if new.respond_to? :choice
        new.choice
      else
        new.sample
      end

system ENV['TODO_FULL_SH'], 'add', hey.strip if hey
