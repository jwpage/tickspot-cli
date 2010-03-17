
# Tickspot CLI #

## Description ##

A command-line interface for the time-tracking website, Tickspot.com.

## Usage ##

Display help information:

    ./tickspot-cli.rb help

Display hours logged for all users, or one specific user:

    ./tickspot-cli.rb check [<user_email>]

Log a Tickspot entry:

    ./tickspot-cli.rb log <time> [-m <log_message>] [--code <task>]

Memorize a Task ID as a string alias:

    ./tickspot-cli.rb memorize <name> [--code <task_id>]

Start the Tickspot timer

    ./tickspot-cli.rb start

Stop the Tickspot timer and log it.

    ./tickspot-cli.rb stop [-m <log_message>] [--code <task>]

## About the `--code` Option

The `--code` option can be either a task\_id, or a string alias as defined by
the `memorize` command.

## TODO ##

* Replace Printer class with Highline for prettiness?
* Add `tickspot start` and `tickspot stop -m "message"`

## Gem Requires ##

* readline
* trollop
* tickspot
* yaml


