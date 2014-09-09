#!/usr/bin/fish
#
# vid.fish -- track which vids have and haven't been seen.
# Copyright (C) 2014 Barry Arthur <barry.arthur@gmail.com>
#
# Distributed under terms of the MIT license.
#

set seen_file .seenit
set now (date +"%Y-%m-%d_%H:%M:%S")
set EXIT_SUCCESS             0
set EXIT_FAIL_NORMAL         1
set EXIT_FAIL_MISUSE         2
set EXIT_FAIL_FILE_NOT_FOUND 3

# helpers {{{

function see-now -a file
  mplayer -zoom -fs -really-quiet $file
end

function ensure-valid -a command
  if not contains $command $commands
    echo "Unknown command: $command"
    usage_all $EXIT_FAIL_NORMAL
  end
end

function ensure-seen-file-exists
  if test ! -f $seen_file
    touch $seen_file
  end
end

function mark-as-seen -a file
  echo -e "$now\t$file" >> $seen_file
end

function ensure-exists -a file
  if test ! -f $file
    echo "File not found: $file"
    exit $EXIT_FAIL_FILE_NOT_FOUND
  end
end

function usage -a command
  set test_status $status
  if test (count $argv) -eq 2
    set exit_status $argv[2]
  else
    set exit_status $EXIT_FAIL_MISUSE
  end
  if test $test_status -ne $EXIT_SUCCESS
    echo -e "usage: vid $command $usages["(contains -i $command $commands)"]"
    exit $exit_status
  end
end

function usage_all -a exit_status
  echo -e "usage: vid command [args]\n\nCommands:\n"
  for command in $commands
    echo -e "$command $usages["(contains -i $command $commands)"]\n"
  end
  exit $exit_status
end

# }}}
# commands {{{

set commands $commands see
set usages $usages "file\n  Adds file to the .seenit file and shows it."
function see -a file
  usage see (test -n $file)
  ensure-exists $file
  mark-as-seen $file
  see-now $file
end

set commands $commands seen
set usages $usages "[pattern]\n  Shows the seen files, optionally matching /pattern/."
function seen -a pattern
  set color --color=always
  if test -z $pattern
    set pattern .
    set color --color=never
  end
  grep $color -i "$pattern" $seen_file
end

set commands $commands seenit
set usages $usages "file-list\n  Adds file-list to the .seenit file."
function seenit
  usage seenit (test -n "$argv")
  for file in $argv
    if test ! -f $file
      echo "File not found: $file"
    else
      mark-as-seen $file
    end
  end
end

set commands $commands unseen
set usages $usages "[pattern]\n  Shows unseen files, optionally matching /pattern/."
function unseen -a pattern
  set color --color=always
  if test -z $pattern
    set pattern .
    set color --color=never
  end

  set seen_all 'find . -type f | grep -i "\.\(mpg\|mp4\|avi\|mkv\|rmvb\|rm\)\$" ' \
    '| sed -e "s/^\\.\\///" | sort | psub'
  set seen_sorted 'sed -e "s/^.*\t//" $seen_file | sort | psub'
  diff (eval $seen_sorted) (eval $seen_all) \
    | grep "^>" | sed -e 's/^> //' | grep $color -i $pattern
end

set commands $commands help
set usages $usages "[command]\n  Shows all help, or optionally for command only."
function help -a command
  if test -n $command
    ensure-valid $command
    usage $command $EXIT_SUCCESS (false)
  else
    usage_all $EXIT_SUCCESS
  end
end

# }}}
# main {{{

set argc (count $argv)

if test $argc -eq 0
  usage_all $EXIT_FAIL_NORMAL
else
  set command $argv[1]
end

if test $argc -gt 1
  set args $argv[2..-1]
else
  set args ""
end

ensure-valid $command
ensure-seen-file-exists
eval $command \$args

#}}}
# vim fdm=marker
