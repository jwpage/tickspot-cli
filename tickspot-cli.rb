require "rubygems"
require "trollop"
require "tickspot"
require "yaml"

# A simple class for handling CLI output with indenting/outdenting.
class Printer
  
  def initialize
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
      out = out + "\t" * @indent + msg + "\n"
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

class TickspotCli

  def initialize(args)
    cmds = %w{check}
    opts = initialize_opts cmds
    @args = args
    comm = @args.shift
    if cmds.include? comm
      continue opts
      self.send comm
    else
      # Force -h on invalid command.
      ARGV.push "-h"
      initialize_opts cmds
    end
  end

  def continue(opts)
    @p = Printer.new
    @p.header "Tickspot CLI"

    if File.exist? opts.config
      @settings = YAML.load_file(opts.config)
    else
      @p.error "Could not find config file "+opts.config
    end
    @tickspot = Tickspot.new(@settings[:tickspot_domain], 
      @settings[:tickspot_email], @settings[:tickspot_password])
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
    opts = Trollop::options do
      opt :user, "User email", :short => "-u", :default => 'all'
    end
    puts "hello world"
  end
end

TickspotCli.new(ARGV)
