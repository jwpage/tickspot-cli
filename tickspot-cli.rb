require "rubygems"
require "trollop"
require "tickspot"
require "yaml"

module TickspotCli
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
  end

  class App 

    def initialize()
      cmds = %w{log check}
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
  
    # Continue processing, load in config file.
    def continue(command, opts)
      @p = Printer.new
      @p.header "Tickspot CLI > "+command.capitalize
      @p.in

      if File.exist? opts.config
        @settings = YAML.load_file(opts.config)
      else
        @p.error "Could not find config file "+opts.config
      end
      @tickspot = Tickspot.new(@settings[:tickspot_domain], 
        @settings[:tickspot_email], @settings[:tickspot_password])

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
      elsif(not timestr.index(':').nil?)
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

  private
    def check
      user = ARGV.shift
      Trollop::options do
        banner "tickspot check [user@email.com]"
      end
      emails = user || @tickspot.users.collect { |u| u.email }

      today = Date.today
      @p.header "Hours Logged for "+today.strftime("%d %b %Y")
      emails.each do |email|
        h = @tickspot.entries(today, today, :user_email => email).collect { |e|
          e.hours.to_f
        }.sum
        @p.puts sprintf("%.2f hours logged by %s", h, email)
      end
    end

    def log
      opts = Trollop::options do
        banner "tickspot log [time] \"[message]\""
        opt :code, "Client/Project/Task code", :short => "-c" 
      end

      minutes = parse_time(ARGV.shift)
      message = ARGV.shift
      if minutes.nil? or message.nil?
        @p.error "Time and message must be provided."
      end
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
