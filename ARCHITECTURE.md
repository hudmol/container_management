This document gives a summary of the overall design and structure of
the new container model implemented by this plugin.

## Logical design

### What's a container?

ArchivesSpace allows you to maintain a separation between the
"intellectual" description of an item and its "physical" description.
To give a concrete example, suppose your collection contains the diary
of some notable person.  In addition to the original physical copy,
you also have a microform version and a digitized (PDF) version.
Within ArchivesSpace, you might represent this as follows:

  * Resource: Notable Person collection

    - Archival Object: Diary

      * Instance: book
        - Container: Box 1

      * Instance: microform
        - Container: Box 1, Reel 2

      * Instance: digital object
        - Digital object: http://mysite.com/objects/my-object-id

Here, the Archival Object record would capture the intellectual
description of the item.  For example, the author's name, the language
the diary was written in, the subjects associated with it, and so
on---information that is inherent to the item, and not specific to a
particular physical medium.

Information about each physical version of the diary gets put in its
corresponding Instance record.  Note that the first two Instance
records have a nested Container record: this gives us a place to
record information about where a physical instance has been stored:
where it's located, which box it's in, how large the box is, and so
on.

So, a container is just a box (or box-like thing).  It exists in the
real world, has physical dimensions, a location, and zero or more
things inside of it.  Using Instance and Container records,
ArchivesSpace keeps track of which boxes exist and exactly what things
are in them.


### How ArchivesSpace represents containers

An Archival Object captures the intellectual description of an item,
and we've seen that Instance records (and their nested Container
records) capture information about a physical version of that item.

At the time of writing, Instance records are actually quite sparse:
almost all of the useful information is contained within the
Instance's Container record.  The Container record contains:

  * type\_1 -- The type of the outermost container

  * indicator\_1 -- The indicator of the outermost container

  * barcode\_1 -- The barcode of the outermost container (only the
    outermost container can have a barcode)

  * type\_2 -- The type of the inner container

  * indicator\_2 -- The indicator of the inner container

  * type\_3 -- The type of the innermost container

  * indicator\_3 -- The indicator of the innermost container

  * container\_extent -- The physical dimensions of the container being described

  * container\_extent\_type -- The units of the above dimensions

  * container\_locations -- The location (and location history) of the
    container being described


The intention of having three-levels here is to support description of
nested containers.  For example "this diary is in Folder C within Box
B1 within Box A" would be represented with Folder C as level 3, Box B1
as level 2, and Box A as level 1.

One limitation of the ArchivesSpace container model is that containers
aren't directly modelled by the system.  Two different items in the
same physical box should have container records within ArchivesSpace
that are field-for-field identical, but the system doesn't know that
these two container records are talking about the same physical box.
This is a carryover from the way containers were represented in the
Archivist's Toolkit.

This limitation makes container management more difficult than it
should be.  If a box is moved, or has its barcode changed, all
container records need to be updated in lockstep, with all of the
opportunities for data inconsistency that this implies.  Something had
to give!  And this led to the new container model implemented by the
plugin whose documentation you are currently reading.


### The new container model

The new container model splits the existing ArchivesSpace container
record into three new record types:

  * A **Top Container** represents the outermost container, and has a
    location, a barcode and an indicator.  It replaces the `barcode_1`
    and `indicator_1` fields from the ArchivesSpace container model.

  * A **Container Profile** represents the type of a Top Container.
    It captures the name and dimensions of a container.

  * A **Subcontainer** represents levels 2 and 3 of the original
    container model.  Like the ArchivesSpace container model, it
    has *type_2*, *indicator_2*, *type_3*, and *indicator_3* fields.

These new record types work together as follows:

  * An ArchivesSpace Instance record can now contain a Subcontainer
    record instead of a Container record.

  * A Subcontainer record links to exactly one Top Container record.
    This records the fact that the physical container(s) represented
    by the Subcontainer record is housed within the outer container
    represented by the Top Container.  A single Top Container may be
    linked to many Subcontainers.

  * A Top Container may optionally link to a (single) Container
    Profile record.  This denotes the fact that a given Top Container
    is of a particular type.

This model alleviates the problems around managing containers by
ensuring that each piece of information that might change has a single
source within the system.  If a box is moved or has its barcode
changed, the single Top Container record can be updated and those
changes automatically apply to all Subcontainers within the system.
And if an instance is moved from one container to another, its
Subcontainer record can just be relinked to the new Top Container.



## The implementation

The new container model is implemented as a plugin with three major
aspects:

  * Changes to the backend code to implement the new data model, batch
    operations on containers, and to map between the ArchivesSpace
    container model and the new container model.

  * Changes to the frontend code to add new interfaces for managing
    containers.

  * Changes to the indexer to make these new records available for
    searching.

We'll work through these aspects in the following sections.

### Backend changes

The backend changes are divided up as follows:

     ├── controllers
     │   ├── container_profile.rb
     │   └── container.rb
     ├── lib
     │   ├── aspace_json_to_yale_container_mapper.rb
     │   └── subcontainer_to_aspace_json_mapper.rb
     ├── model
     │   ├── accession_ext.rb
     │   ├── archival_object_ext.rb
     │   ├── container_profile.rb
     │   ├── instance_ext.rb
     │   ├── resource_ext.rb
     │   ├── sub_container.rb
     │   └── top_container.rb
     │   ├── mixins
     │   │   ├── archival_object_series.rb
     │   │   ├── map_to_aspace_container.rb
     │   │   ├── reindex_top_containers.rb
     │   │   ├── rights_statement_restrictions.rb
     │   │   └── sub_containers.rb
     ├── plugin_init.rb


  * the `controllers` directory contains the definitions of the REST
    endpoints used to query and update the new record types.  These
    follow the standard ArchivesSpace controller conventions.

  * the `lib` directory contains two "mapper" classes that implement
    the mappings between the existing ArchivesSpace container model
    and the new container model:

      - `aspace_json_to_yale_container_mapper.rb` takes the JSONModel
        representation of an ArchivesSpace record (such as an
        Accession, Resource or Archival Object) and converts any
        embedded Container records into the equivalent configuration
        of Subcontainer, Top Container and Container Profile records.

      - `subcontainer_to_aspace_json_mapper.rb` does the inverse: it
        takes a record expressed in the new container model and
        produces the equivalent ArchivesSpace container record.

    these two classes provide compatibility between the existing
    ArchivesSpace container model and the new container model, so that
    code written in terms of the ArchivesSpace container model
    continues to function normally.

  * The `model` directory contains the code responsible for storing
    and loading the new container model objects to and from the
    database:

      - Files ending in `_ext.rb` are the ArchivesSpace plugin
        system's way of extending the existing ArchivesSpace models.
        These don't contain any real code: they just use ruby modules
        to "mix in" new functionality defined in the `mixins`
        directory.

     - `top_container.rb`, `sub_container.rb` and
       `container_profile.rb` contain the code for saving, storing and
       manipulating the new record types to/from/within the database.
       Of the three, `top_container.rb` is the most interesting: in
       addition to the usual database mappings, it also contains the
       logic for performing batch updates of Top Container records.

  * The `model/mixins` directory contains ruby modules that implement
    particular concerns of the new container model.  Working through
    these:

      - `archival_object_series.rb` is mixed in to the standard
        ArchivesSpace Archival Object record.  It adds support for
        determining which series a given Archival Object belongs to.

      - `map_to_aspace_container.rb` is mixed in to any ArchivesSpace
        record supporting instances (at the time of writing:
        Accession, Resource and Archival Object records).  This
        adds the necessary hooks to run incoming and outgoing records
        through the mapping processes defined by the two mappers in
        the `lib` directory.

      - `reindex_top_containers.rb` adds hooks to the Archival Object
        update process to ensure that linked Top Containers are
        reindexed at the right moments.  Since Top Container records
        are indexed with information about the records they link to,
        it's important that they get reindexed when those linkages
        change.

      - `rights_statement_restrictions.rb` adds support for asking an
        Accession, Resource or Archival Object record to determine
        whether its ArchivesSpace rights records would cause it to be
        marked as restricted.

      - `sub_containers.rb` adds support for the new Subcontainer
        record to existing ArchivesSpace Instance records.

  * Finally, `plugin_init.rb` gets loaded when the plugin is loaded.
    It loads everything, defines some new permissions and sets up the
    compatibility mapping for the record types that need it.


### Staff interface changes

The changes we have seen so far deal with modifying the ArchivesSpace
data model to support the new container structure.  Within the staff
interface (sometimes called the "frontend"), there are new template,
CSS and JavaScript files that provide the user interfaces for creating
and managing the new types of records.  There are also a handful of
places where the standard ArchivesSpace templates have been
overridden--these places are noted below.

Modifications to the staff interface are contained in the `frontend`
directory, whose structure is as follows:


     ├── assets
     │   ├── box.png
     │   ├── container_profile.png
     │   ├── jquery.tablesorter.min.js
     │   ├── top_containers.bulk.css
     │   ├── top_containers.bulk.js
     │   ├── top_containers.crud.js
     │   ├── yale_container_loading.gif
     │   ├── yale_containers.css
     │   └── yale_containers.index.js
     ├── controllers
     │   ├── container_profiles_controller.rb
     │   └── top_containers_controller.rb
     ├── locales
     │   ├── enums
     │   │   └── en.yml
     │   └── en.yml
     ├── plugin_init.rb
     ├── routes.rb
     └── views
         ├── container_profiles
         │   ├── edit.html.erb
         │   ├── _form.html.erb
         │   ├── index.html.erb
         │   ├── _linker.html.erb
         │   ├── _listing.html.erb
         │   ├── _new.html.erb
         │   ├── new.html.erb
         │   ├── show.html.erb
         │   ├── _sidebar.html.erb
         │   └── _toolbar.html.erb
         ├── instances
         │   ├── _show.html.erb
         │   ├── _subrecord_form_action.html.erb
         │   └── _template.html.erb
         ├── layout_head.html.erb
         ├── sub_containers
         │   ├── _show.html.erb
         │   └── _template.html.erb
         └── top_containers
             ├── bulk_operations
             │   ├── _browse.html.erb
             │   ├── _bulk_action_success.html.erb
             │   ├── _bulk_action_templates.html.erb
             │   ├── _collection_linker.html.erb
             │   ├── _container_profile_linker.html.erb
             │   ├── _error_messages.html.erb
             │   ├── _location_linker.html.erb
             │   ├── _results.html.erb
             │   ├── _search_criteria.html.erb
             │   ├── _series_linker.html.erb
             │   └── _toolbar.html.erb
             ├── edit.html.erb
             ├── _form.html.erb
             ├── index.html.erb
             ├── _linker.html.erb
             ├── _new.html.erb
             ├── new.html.erb
             ├── show.html.erb
             ├── _sidebar.html.erb
             └── _toolbar.html.erb


  * The `assets` directory contains CSS, JavaScript and other static
    content.

  * The `controllers` directory contains the custom controllers that
    have been added to the frontend Rails application.  These handle
    CRUD-style requests for the new record types, plus requests for
    things like full-text searches searches, type-ahead search and
    bulk update operations.

  * The `locales` directory contains I18n strings used by the
    application (in YAML format).  There is one file that translates
    enumerations, and one that translates everything else.

  * The `plugin_init.rb` file gets loaded when the application first
    starts up.  This deals with overriding some of the search defaults
    inherited from the standard ArchivesSpace configuration and
    eagerly loads some of the JSONModel schemas we make use of.

  * The `routes.rb` file adds the extra Rails URL routes that direct
    requests to our custom controllers.

  * The `views` directory contains one set of templates for each of
    the new record types.  This includes the standard ArchivesSpace
    templates for:

      - the read-only record view
      - record edit forms
      - the record sidebar
      - toolbar actions
      - record browse listings

    Note here that any template that shares a name with a standard
    ArchivesSpace template will override it.  In particular, the files
    under the `instances` directory override their ArchivesSpace
    counterparts.


### Indexer changes

To allow the new record types to be made searchable, several
additional indexing rules have been defined.  You can find these
definitions under `indexer/indexer.rb`.

The code in this file gets invoked whenever a document is about to be
added to the index, and we use this to add additional fields where
required.  The field names make use of Solr's "dynamic fields"
functionality: by giving them predictable suffixes, we save the need
to modify the ArchivesSpace Solr schema.  You can see the list of
available suffixes by inspecting the ArchivesSpace Solr schema:

  https://github.com/archivesspace/archivesspace/blob/master/solr/schema.xml

and searching for "dynamicField" (around line 181 at time of writing).
