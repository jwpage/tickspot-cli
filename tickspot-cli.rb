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
      cmds = %w{check}
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

  private
    def check
      user = ARGV.shift
      Trollop::options do
        banner "tickspot check [user@email.com]"
      end
      emails = user || @tickspot.users.collect { |u| u.email }

      today =  (@settings[:debug] && Date.parse('05-02-2010')) || Date.today
      @p.header "Hours Logged for "+today.strftime("%d %b %Y")
      emails.each do |email|
        h = @tickspot.entries(today, today, :user_email => email).collect { |e|
          e.hours.to_f
        }.sum
        @p.puts sprintf("%.2f hours logged by %s", h, email)
      end
    end

    def log
      #
      #opts = Trollop::options do
      #  opt :code, "Client/Project/Task code", :short => "-c" 
      #  opt :hours, "Hours", :short => "-h", :default => 0, :type => :int
      #  opt :msg, "Message", :short => "-m", :default => ""
      #end
    end
  end
end

TickspotCli::App.new()
