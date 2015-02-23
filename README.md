Yale Containers
===============

ArchivesSpace plugin to add a new container type to ArchivesSpace.
More information on these at
http://campuspress.yale.edu/yalearchivesspace/2014/11/20/managing-content-managing-containers-managing-access/.

## Installing it

To install, just activate the plugin in your config/config.rb file by
including an entry such as:

     # If you have other plugins loaded, just add 'yale_containers' to
     # the list
     AppConfig[:plugins] = ['local', 'other_plugins', 'yale_containers']

And then clone the `yale_containers` repository into your
ArchivesSpace plugins directory.  For example:

     cd /path/to/your/archivesspace/plugins
     git clone https://github.com/hudmol/yale_containers.git yale_containers


## Upgrading from a previous release

Each release of this plugin comes with some database schema changes
that need to be applied.  To upgrade from a previous release:

  1. Replace your `/path/to/archivesspace/plugins/yale_containers`
     directory with the new release version

  2. Run the database setup script to update all tables to the latest
     version:

          cd /path/to/archivesspace
          scripts/setup-database.sh

## Temporary workaround for "Full head" errors

The top container linker passes a large amount of data to the frontend
in some cases, which causes errors like this to appear in the logs:

     2015-02-23 11:39:10.672:WARN:oejh.HttpParser:HttpParser Full for SCEP@3eec285c{l(/a.b.c.d:xxxxx)<->r(/l.m.n.o:yyyy),d=true,open=true,ishut=false,oshut=false,rb=false,wb=false,w=true,i=0r}-{AsyncHttpConnection@5401a48f,g=HttpGenerator{s=0,h=-1,b=-1,c=-1},p=HttpParser{s=-10,l=0,c=-3},r=0}

There's a pull request against the ArchivesSpace project to address
this issue:

  https://github.com/archivesspace/archivesspace/pull/136

but as a temporary workaround, you can increase Jetty's request buffer
size.  To do that, copy the file `launcher_rc.rb` from this directory
into your top-level archivesspace directory, and then restart
ArchivesSpace.  When the system starts up, you should see messages
like:

     Increasing buffer size for SelectChannelConnector@0.0.0.0:8080 to 32768

There's no harm in running with this option indefinitely (it will
increase the amount of memory used per-request, but not by an amount
that would matter), but it can be safely removed once the above pull
request has been merged and released in a future ArchivesSpace
version.
