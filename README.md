# Perforce Helix (p4) Command Line Tools

## Bash functions

Define some helpful commands for working with p4 as follows

    source p4func.sh

This defines a number of Bash function all prefixed by `htp4`.

You can get a quick overview by executing

    declare -f | grep -A2 '\<htp4'

To use them more simply you can define some aliases for the most frequently
used ones. Here are my favourites.

    alias i=htp4info # show user, server and connection status

    # show opened files
    alias o='p4 opened' # basic
    alias oo=htp4opened # fancier

    alias c=htp4changes # opened and shelved files

    alias p4df=htp4df # show opened files diffs (p4 diff) in vim
    alias p4df2=htp4df2 # p4 diff2 in vim
    alias p4dsc=htp4dsc # p4 describe in vim

    # some 'straight' aliases to p4 commands I often use
    alias pfs='p4 status'
    alias pfr='p4 reconcile'

## Shell prompt

If you source the following

    source p4-prompt.sh

It defines the function `__p4_stream_ps1` that you can use to show the p4
stream you are currently working on. You also need to set the environment
variable `P4_STREAM_PS1_SHOW` to activate it.

For example

    P4_STREAM_PS1_SHOW=1
    PS1="$(__p4_stream_ps1)\$ "

Now if you are logged on to Perforce and your working directory is within a
workspace connected to a stream whose `Name` attribute is `stream-name` the
prompt will show:

    (stream-name)$

Otherwise it will show just:

    $

**Warning** The prompt will be 'empty' if are not logged on to Perforce
regardles of anyting else.  I run the `i` alias frequently to check for this
and avoid the confusion.
