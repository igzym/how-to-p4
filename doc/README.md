How to P4
=========

Helpers
-------

Shell functions I use when working with p4 cmd line are part of this repo.


The p4 command
--------------

Here are the most frequently used `p4` operations

* p4 info
* p4 login
* p4 set -- your p4 environment settings (client name, config file etc) and where they came from
* p4 client -- workspace / client operations
* p4 edit / p4 add / p4 delete / p4 move -- define changelists contents
* p4 submit -- push changes to the server
* p4 sync -- get updates from the server
* p4 shelve -- temporary save a changelist on the server without actually committing it
* p4 change -- create new pending changelist or display an existing one
* p4 describe -- show information about a changelist
* p4 changes -- list changelists
* p4 interchanges -- summary of changes between two branches / codelines
* p4 resolve -- finalise an integration or a sync where you had opened files
* p4 revert -- discard the uncommitted changes to files in your working directory
* p4 filelog -- detailed file hisotry
* p4 merge / p4 copy (and p4 integ for the courageous)


Workspaces aka Clients
----------------------

* _Workspace_ and _client_ are used synonymously. I'll often use client because
  it's shorter.
* **A client defines a link between files in the repository on the server and
  their copies on your local hard drive.**
* Creating a client _does not create local files_
* Creating a client _does not create server files_ either, or require them to
  exist

Prepare for using a client `igm-how`,  which may or may not already exist.

    mkdir igm-how # this is the root directory of my client
    cd igm-how
    echo "P4CLIENT=igm-how" >$P4CONFIG

The environment variable `P4CONFIG` is the name of a the config file where the
`p4` command will read its configuration from. It ascends the subdirectory
chain in search of it. Multiple config files can be placed at different levels
along the path and their effect is cummulative.

A common choice for this file is `.p4config`. I personnally use `P4CONFIG`
because I like it to be very visible.

If the client indicated in the configuration exists you can start using it, for
example via `p4 sync` to get the files.  Otherwise you need to create it. We'll
see that in the next section.


Streams
-------

### Create a stream

The following displays a 'spec' of a non-yet-existent stream `//project/widget/main`

    p4 --field Name=widget-main stream -t mainline -o //project/widget/main

To create the stream, we simply feed it into `p4 stream -i`. This is a common
pattern for other objects. Notice the use of `--field` option.

    p4 --field Name=widget-main stream -t mainline -o //project/widget/main | p4 stream -i


*Note* This stream is empty. Like a client, it's a specification of what the
contents should be like, but the contents must be created separately via submit
operations.

Assuming that our client `igm-how` does not yet exist, we can create it and
connect it to this new stream.

    p4 --field Stream=//project/widget/main --field LineEnd=share --field Options=rmdir client -o | p4 client -i

If we try

    p4 sync

the server will respond with `No such file(s).`, which is normal, we haven't created any content yet.


Files
-----

    mkdir src
    echo 'main(int argc, char **argv) {}' >src/main.cpp
    p4 add src/main.cpp
    o # alias for p4 opened


Changelist
----------

A change list is a change packet that is applied in its entirety or not at all.

It consists of the following:

* change number
* description
* date and time
* list of files and what was done on them (edit, add, delete, integrate...)
* change contents (diffs, file contents)

Change numbers of committed changelists are monotonically increasing. A
'pending' changelist can have a number, but this number may be changed
automatically by the server upon committing it to respect the monotonocity.

Create a changelist using

    p4 change

This opens change specification in the editor. All open files in the 'default'
change are automatically added. You can remove some or all of them.

You must supply a change description


Create another client
---------------------

    cd ..
    mkdir igm-how-2
    cd !!$
    echo P4CLIENT=igm-how-2 >$P4CONFIG
    # copy all 'global' parameters from igm-how
    # but change client name (obviously) and the path to client local files
    p4 client -t igm-how -o | p4 client -i
    # it is not in the right state: must switch to the stream
    p4 client -s -S //project/widget/main -f # -f necessary first time after creation

    p4 sync

Branching
---------

Create a child stream `dev`

    p4 --field Name=widget-dev stream -t development -P //project/widget/main -o //project/widget/dev | p4 stream -i


Branch a stream from its parent stream.

    p4 populate -S //project/widget/dev -r

This branches and commits the change with an automatically generated comment.
It's efficient because all is done on the server, no need to transfer any files
between server and client.

If you wanted to do in explicit steps

    p4 merge -S //project/widget/dev -r
    p4 submit # and provide a description

### On the -r option

When working with streams using `-S` option the default flow of change is _from
child to parent_. For example copy 'dev' to 'main'.

Adding `-r` reverses this to _parent to child_ (merge, populate).

Shelves
-------

You can store a change on the server without committing it. This is called a
_shelf_. Uses of shelving:

* save work in progress to switch to something else
* transfer / copy a change between clients and users
* code review - _Swarm_ application is implemented using shelves.
