
# Tickspot CLI #

## Description ##

A command-line interface for the time-tracking website, Tickspot.com.

## Usage ##

Display help information:

    ./tickspot-cli.rb help

Display hours logged for all users, or one specific user:

    ./tickspot-cli.rb check [<user_email>]

Log a Tickspot entry:

    ./tickspot-cli.rb log <time> [-m <log_message>] [--code <task_id>]

## TODO ##

* Replace Printer class with Highline for prettiness?

## Gem Requires ##

* readline
* trollop
* tickspot
* yaml


