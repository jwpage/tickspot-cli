require 'rubygems'
require 'trollop'
require 'tickspot'
require 'yaml'

class TickspotCli

    def initialize(args)
        cmds = %w{check}
        initialize_help cmds
        @args = args
        comm = @args.shift
        if cmds.include? comm
            self.send comm
        else
            # Force -h on invalid command.
            ARGV.push "-h"
            initialize_help cmds
        end
    end

    def initialize_help(stop_cmds)
        opts = Trollop::options do
            banner "Tickspot CLI interface"
            opt :config, 
                "Path to tickspot-cli config file", 
                :short => "-c", 
                :default => File.expand_path('~/.tickspot-cli.yaml')
            stop_on stop_cmds
        end
    end


private
    def check
        opts = Trollop::options do
            opt :user, "User email"
        end
        puts 'hello world'
    end
end

TickspotCli.new(ARGV)
