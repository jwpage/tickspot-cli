require 'rubygems'
require 'trollop'

class TickspotCli
    def initialize(args)
        @cmds = %w{check}
        @args = args
        comm = @args.shift
        if @cmds.include? comm
            self.send comm
        else
            help
        end
    end

private
    def check
        puts 'hello world'
    end

    def help
        puts 'you\'re doing it wrong'
    end
end

TickspotCli.new(ARGV)