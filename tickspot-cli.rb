#!/usr/bin/ruby
require "rubygems"
require "readline"
require "trollop"
require "tickspot"
require "yaml"

class Tickspot
  def clients_projects_tasks
    te = request("clients_projects_tasks")
    te.empty? ? [] : te.clients
  end
  def create_entry(task_id, hours, note)
    te = request("create_entry", {
      :task_id => task_id, 
      :hours => hours, 
      :notes => note,
      :date => Date.today.to_s})
  end
end

class TickspotEntry
  def method_missing(method, *args)
    if @hash.has_key?(method.to_s.singularize)
      entry = @hash[method.to_s.singularize]
      if method.to_s.pluralize == method.to_s && entry.class == Array
        return entry.collect {|e| TickspotEntry.new(e)}
      else
        return entry[0] unless entry[0].class == Hash && entry[0].has_key?("content")
        return entry[0]["content"]
      end
    elsif @hash.has_key?(method.to_s)
      entry = @hash[method.to_s]
      if method.to_s.pluralize == method.to_s && entry[0][method.to_s.singularize].class == Array
        return entry[0][method.to_s.singularize].collect {|e| TickspotEntry.new(e)}
      else
        return entry[0] unless entry[0].class == Hash && entry[0].has_key?("content")
        return entry[0]["content"]
      end
    else
      super 
    end
  end
end

module TickspotCli
  # Simple class for handling YAML files
  class Settings
    @@data = nil
    @@filename = nil

    def self.load(filename)
      return if @@data

      if File.exist? filename
        @@filename = filename
        @@data = YAML.load_file filename
      else
        @@data = {}
      end
    end

    def self.[](key)
      @@data[key]
    end

    def self.[]=(key, value)
      @@data[key] = value
      @@data.delete(key) if value.nil?
    end

    def self.save
      File.open(@@filename, "w") do |out|
        out.puts @@data.to_yaml
      end
    end
  end
  # A simple class for handling CLI output with indenting/outdenting.
  class Printer
    
    def initialize
      @tab = "  "
      @indent = 0
    end
    def in
      @indent = @indent.next
      self
    end

    def out
      @indent = [0, @indent - 1].max
      self
    end

    def reset
      @indent = 0
      self
    end

    def puts(msg)
      STDOUT.puts format(msg)
    end

    def format(*msgs)
      out = ""
      msgs.each do |msg|
        out = out + @tab * @indent + msg + "\n"
      end
      out
    end

    def header(msg)
      STDOUT.puts format msg, "-" * msg.length
    end

    def error(msg)
      msg = "Error: "+msg
      STDOUT.puts format("-" * msg.length, msg, "-" * msg.length)
      exit
    end

    # Yeah, even though this class is called Printer
    def readline
      Readline::readline(@tab * @indent + "> ")
    end
  end

  class App 

    def initialize()
      cmds = %w{log check today start stop}
      opts = initialize_opts cmds
      comm = ARGV.shift
      if cmds.include? comm
        continue comm, opts
      else
        # Force -h on invalid command.
        ARGV.push "-h"
        initialize_opts cmds
      end
    end

    def start
      Settings[:tickspot_start] = Time.now()
      Settings.save
      @p.puts "Started timer."
    end

    def stop
      opts = Trollop::options do
        banner "tickspot stop  [-m \"message\"] [-c code]"
        opt :message, "Note", :short => "-m", :type => String, :default => ""
        opt :code, "Client/Project/Task code", :short => "-c", :type => :int 
      end

      started = Settings[:tickspot_start]
      if not started
        @p.error  "You should probably start the timer first. "+
                  "Try `tickspot-cli.rb start`"
        return
      end

      hours = (((Time.now() - started) / 60 / 60) * 100).ceil.to_f / 100
      Settings[:tickspot_start] = nil
      Settings.save
      
      task_id = get_task_id(opts[:code])
      @p.puts ""
      if @tickspot.create_entry(task_id, hours, opts[:message])
        @p.puts "Stopped timer. Created entry for #{hours} hours."
      end

      # Show chooser
      # Log time

    end
    
    # Get a user's current entries for the day
    def today
      user = ARGV.shift || Settings[:tickspot_email]
      Trollop::options do
        banner "tickspot today [user@email.com]"
      end
      day = Date.today
      @p.header "Entries Logged for "+day.strftime("%d %b %Y")
      total = 0
      @tickspot.entries(day.to_s, day.to_s, :user_email => user).each_with_index do |e, i|
        @p.puts "#{i+1}. #{e.hours} hours: #{e.client_name}> #{e.project_name}> #{e.task_name} - #{e.notes}"
        total = total + e.hours.to_f
      end
      @p.puts ""
      @p.puts "TOTAL: #{total} hours"
    end

    # Check how much other users have tickspotted today.
    def check
      user = ARGV.shift
      Trollop::options do
        banner "tickspot check [user@email.com]"
      end
      emails = user || @tickspot.users.collect { |u| u.email }

      day = Date.today
      @p.header "Hours Logged for "+day.strftime("%d %b %Y")
      emails.each do |email|
        h = @tickspot.entries(day, day, :user_email => email).collect { |e|
          e.hours.to_f
        }.sum
        @p.puts sprintf("%.2f hours logged by %s", h, email)
      end
    end

   # Create a new tickspot entry.
   def log
      minutes = parse_time(ARGV.shift)
      if minutes.nil?
        @p.error "Time must be provided."
      end
      opts = Trollop::options do
        banner "tickspot log [time]  [-m \"message\"]"
        opt :message, "Note", :short => "-m", :type => String, :default => ""
        opt :code, "Client/Project/Task code", :short => "-c", :type => :int 
      end

      task_id = get_task_id(opts[:code])
      @p.puts ""
      if @tickspot.create_entry(task_id, minutes/60, opts[:message])
        if opts[:code]
          @p.puts "Created entry."
        else
          @p.puts "Created entry. In the future you can use '--code #{task_id}' for this task."
        end
      end
    end
 
  private

    def get_task_id(code)
      if not code
        cpt = @tickspot.clients_projects_tasks
        client = log_select cpt, "client"
        project = log_select cpt[client].projects, "project"
        task = log_select cpt[client].projects[project].tasks, "task"

        task_id = cpt[client].projects[project].tasks[task].id
      else
        task_id = code
      end
    end

    # Continue processing, load in config file.
    def continue(command, opts)
      @p = Printer.new
      @p.header "Tickspot CLI > "+command.capitalize
      @p.in

      if File.exist? opts.config
        Settings.load opts.config
      else
        @p.error "Could not find config file "+opts.config
      end
      @tickspot = Tickspot.new(Settings[:tickspot_domain], 
        Settings[:tickspot_email], Settings[:tickspot_password])

      self.send command
    end

    # Initial global options and help information.
    def initialize_opts(stop_cmds)
      opts = Trollop::options do
        banner "Tickspot CLI interface"
        opt :config, 
          "Path to tickspot-cli config file", 
          :short => "-c", 
          :default => File.expand_path("~/.tickspot-cli")
        stop_on stop_cmds
      end
    end

    # Should parse:
    # :30 => 30
    # 1h => 60
    # 30m => 30
    # 1h30m => 90
    # 0:30 => 30
    # 1.5 => 90
    # 1 => 60
    # 0.5 => 30
    # 16 => 16 -- >10 hours are assumed to be minutes
    # 8 => 480
    def parse_time(timestr)
      return 0 if timestr.nil?
      
      h = 0
      m = 0

      if(not timestr.index(/(h|m)/).nil?)
        h = timestr.scan(/(\d*)\s*h/i).flatten.last
        m = timestr.scan(/(\d*)\s*m/i).flatten.last
      elsif(not timestr.index(":").nil?)
        h = timestr.scan(/(\d+)\s*?:/).flatten.last
        m = timestr.scan(/:\s*(\d{2})/).flatten.last
      elsif(not timestr.index(/\d*?(\/\d*)?/).nil?)
        h = timestr.to_f
        if(h > 10)
          m = h
          h = 0
        end
      end
      (h.to_f * 60) + m.to_f
    end
  
    # Display 'Select a ' prompts for the log action.
    def log_select(arr, name)
      @p.puts ""
      @p.puts "Select a #{name}:"
      @p.in
      arr.each_with_index do |k, i|
        @p.puts "#{i+1}. #{k.name}"
      end
      @p.out.readline.to_i-1
    end
 end
end

TickspotCli::App.new()

=begin Just some time parsing tests
tests = { 
  ":30" => 30,
  "1h" => 60,
  "30m" => 30,
  "1h30m" => 90,
  "0:30" => 30,
  "1.5" => 90,
  "1" => 60,
  "0.5" => 30,
  "16" => 16,
  "8" => 480,
}
app = TickspotCli::App.new
tests.each do |k,v|
  puts app.parse_time(k) == v
end
=end
