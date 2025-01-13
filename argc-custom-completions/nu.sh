#!/usr/bin/env bash
# Automatic generated, DON'T MODIFY IT.

# @flag -h --help:                           Display the help message for this command
# @option -c --commands <<string>:>          run the given commands and then exit
# @option -e --execute <<string>:>           run the given commands and then enter an interactive shell
# @option -I --include-path <path:>          set the NU_LIB_DIRS for the given script (delimited by char record_sep (''))
# @flag -i --interactive:                    start as an interactive shell
# @flag -l --login:                          start as a login shell
# @option -m --table-mode <<string>:>        the table mode to use.
# @option --error-style <<string>:>          the error style to use (fancy or plain).
# @flag --no-newline:                        print the result for --commands(-c) without a newline
# @flag -n --no-config-file:                 start with no config file and no env file
# @flag --no-history:                        disable reading and writing to command history
# @flag --no-std-lib:                        start with no standard library
# @option -t --threads <<int>:>              threads to use for parallel commands
# @option -v --version: <print> <the> <version>
# @option --config <<path>:>                 start with an alternate config file
# @option --env-config <<path>:>             start with an alternate environment config file
# @flag --lsp:                               start nu's language server protocol
# @option --ide-goto-def <<int>:>            go to the definition of the item at the given position
# @option --ide-hover <<int>:>               give information about the item at the given position
# @option --ide-complete <<int>:>            list completions for the item at the given position
# @option --ide-check <<int>:>               run a diagnostic check on the given source and limit number of errors returned to provided number
# @flag --ide-ast:                           generate the ast on the given source
# @option --plugin-config <<path>:>          start with an alternate plugin registry file
# @option --plugins <<list<path>>:>          list of plugin executable files to load, separately from the registry file
# @option --log-level[error|warn|info|debug|trace] <<string>:>  log level for diagnostic logs.
# @option --log-target <<string>:>           set the target for the log to output.
# @option --log-include <<list<string>>:>    set the Rust module prefixes to include in the log output.
# @option --log-exclude <<list<string>>:>    set the Rust module prefixes to exclude from the log output
# @flag --stdin:                             redirect standard input to a command (with `-c`) or a script file
# @option --testbin <<string>:>              run internal test binary
# @arg file
# @arg args*

command eval "$(argc --argc-eval "$0" "$@")"
