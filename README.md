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


## Migrating your existing ArchivesSpace installation

This plugin provides a mechanism to perform a bulk conversion of your
existing ArchivesSpace database to the new container model.  If you
are applying this plugin to an existing ArchivesSpace installation
(with pre-existing container data) you should apply these steps.

Please be aware that your ArchivesSpace installation must be *stopped*
while the conversion is running, so this migration will require some
scheduled downtime.  It's a good idea to run the migration on a copy
of your database first: this will give you an idea of how long the
migration will take, and will also give you a chance to fix any
underlying data issues reported by the migration process.  As a rough
estimate, a database with 350,000 Archival Object records (and MySQL
running on the same machine) was migrated in around 2.5 hours.

To perform the migration:

  * Follow the installation steps above.

  * Start your ArchivesSpace instance and verify that everything loads
correctly.  If you browse to the ArchivesSpace staff interface, you
should see an entry for "Manage container profiles" under the
"Plug-ins" dropdown menu.

  * Shut down ArchivesSpace

  * Add the following entry to your `config/config.rb` file:

         AppConfig[:migrate_to_container_management] = true

  * Start ArchivesSpace again.  You should see the migration log a
    large number of messages as it runs.

  * Once the migration finishes, shut down ArchivesSpace.

  * Search the ArchivesSpace log for any "ERROR" messages.  A common
    case is where two container records in ArchivesSpace claim to
    represent the same container, but have different metadata.  For
    example:

         [java] E, [2015-03-11T10:03:03.138000 #2315] ERROR -- : Thread-3438: A ValidationException was raised while the container migration took place.  Please investigate this, as it likely indicates data issues that will need to be resolved by hand
         [java] E, [2015-03-11T10:03:03.139000 #2315] ERROR -- :
         [java] #<:ValidationException: {:errors=>{"indicator_1"=>["Mismatch when mapping between indicator and indicator_1"]}, :object_context=>{:top_container=>#<TopContainer @values={:id=>31219, :repo_id=>2, :lock_version=>9, :json_schema_version=>1, :barcode=>"0118999880199157253", :restricted=>0, :indicator=>"32", :created_by=>"admin", :last_modified_by=>"admin", :create_time=>2015-03-10 23:02:50 UTC, :system_mtime=>2015-03-10 23:03:03 UTC, :user_mtime=>2015-03-10 23:02:50 UTC, :ils_holding_id=>nil, :ils_item_id=>nil, :exported_to_ils=>nil, :override_restricted=>0, :legacy_restricted=>0}>, :aspace_container=>{"lock_version"=>0, "indicator_1"=>"24", "barcode_1"=>"31142042186752", "indicator_2"=>"3b", "created_by"=>"admin", "last_modified_by"=>"admin", "create_time"=>"2013-12-04T02:29:18Z", "system_mtime"=>"2013-12-04T02:29:18Z", "user_mtime"=>"2013-12-04T02:29:18Z", "type_1"=>"box", "type_2"=>"folder", "jsonmodel_type"=>"container", "container_locations"=>[]}}}>

    This suggests that there are two container records in
    ArchivesSpace with the same barcode, but one with indicator_1 of
    "32" and another with "24".  The migration process will continue,
    but the value(s) from the `aspace_container` entry shown will be
    discarded in favor of the `top_container` values.  You may need to
    clean up the records by hand once the migration has completed.

  * Edit your `config/config.rb` and remove the entry for
    `:migrate_to_container_management` (or change it to `false`).

  * Restart ArchivesSpace and wait for reindexing to complete.

  * Verify that your container records have been migrated correctly.


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
