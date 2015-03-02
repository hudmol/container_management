This document gives a summary of the overall design and structure of
the new container model implemented by this plugin.

## What's a container?

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


## How ArchivesSpace represents containers

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


## The new container model

