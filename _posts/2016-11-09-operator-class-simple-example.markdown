---
layout: post
title:  "A simple example to demo custom data type and operator class"
author: Pivotal Engineer
date:   2016-11-09 23:00 +0800
categories: gpdb operator class
published: true
---

## Index Access Method

There are well defined interfaces between core PostgreSQL system and index access methods, which manage individual index
types. The core system knows nothing about index beyond the interface, so it is easy to develop entirely new index types
by writing add-on code.

All indexes in PostgreSQL are called as secondary indexes, it is physically separate from the table file that it describes.
Each index is stored as its own physical relation and so is described by an entry in the pg_class catalog. The contents of
an index are entirely under the control of its index access method.  In practice, all index access methods divide indexes
into standard-size pages so that they can use the regular storage manager and buffer manager to access the index contents.

An index is effectively a mapping from some data key values to `tuple identifiers` or TIDs, of row versions (tuples) in
the index's parent table. TID consists of a block number and an item number within that block.

Indexes are not directly aware that under MVCC, there might be multiple extant versions of the same logical row; to an index,
each tuple is an independent object that needs its own index entry.  Thus an update of a row always creates all-new index
entries for the row, even if the key values did not change.  Index entries for dead tuples are reclaimed (by vacuuming)
when the dead tuples themselves are reclaimed.

Each index access method is described by a row in the `pg_am` system catalog. The principal contents of a pg_am row are
references to pg_proc entires that identify the index access functions supplied by the access method.

# Operator class

In PostgreSQL, operator class allows to implement own indexing strategies.

In PostgreSQL, you could define your own new types, new functions and new operators.
You could also define an index on a column of a new data type. To do this, you must define
an `operator class` for the new data type. Otherwise, the new defined type could not be sorted
or indexscan.

Operator classes can be grouped into operator families to show the relationships between
semantically compatible classes. When only a single data type is involved, an operator class is
sufficient.

## Index methods and operator classes

The `pg_am` table contains one row for every index method (internally known as access method).
It is possible to add new index method by defining the required interface routines, and then creating
a row in pg_am. Currently support index method:

    d1=# SELECT amname from pg_am;
     amname
    --------
     btree
     hash
     gist
     gin
     bitmap
    (5 rows)

The routines for an index method does not directly know anything about the data types that the index
method will operate on. Instead, an `operator class` identifies the set of operations that the index
method needs to use to work with a particular data type.

It is possible to define multiple operator classes for the same data type and index method.

The same operator class name can be used for several different index methods (eg, both B-tree and hash index methods
have operator classes named int4_ops).

## Index Method Strategies

The operator associated with an operator class are identified by "strategy numbers", which serve to
identify the semantics of each operator within the context of its operator class.

B-Tree index method defines 5 strategies:


    Operation	            Strategy Number
    less than	            1
    less than or equal	    2
    equal	                3
    greater than or equal	4
    greater than	        5

## Index Method Support Routines

Strategies aren't usually enough info for the system to figure out how to use an index. In practice,
the index methods require additional support routines in order to work.

## Operator classes and operator families

An operator family contains one or more operator classes, and can also contain indexable operators and
corresponding support functions that belong to the family as a whole but not to any single class
within the family. Typically each operator class contains single-data-type operators while cross-data-type
operators are loose in the family.

All the operators and functions in an operator family must have compatible semantics, where the compatibility
requirements are set by the index method. It is major used to specify how much of the family is needed to
support any particular index.

## An example for user defined type and operator class

    CREATE TYPE mytype AS (f1 int);

    CREATE FUNCTION mytype_eq(mytype, mytype)
    RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int4eq';

    CREATE FUNCTION mytype_ne(mytype, mytype)
    RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int4ne';

    CREATE FUNCTION mytype_lt(mytype, mytype)
    RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int4lt';

    CREATE FUNCTION mytype_le(mytype, mytype)
    RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int4le';

    CREATE FUNCTION mytype_gt(mytype, mytype)
    RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int4gt';

    CREATE FUNCTION mytype_ge(mytype, mytype)
    RETURNS boolean LANGUAGE internal IMMUTABLE AS 'int4ge';

    CREATE FUNCTION mytype_cmp(mytype, mytype)
    RETURNS integer LANGUAGE internal IMMUTABLE AS 'btint4cmp';

    CREATE FUNCTION hash_mytype(mytype)
    RETURNS integer LANGUAGE internal IMMUTABLE AS 'hashint4';

    CREATE OPERATOR = (
      LEFTARG = mytype,
      RIGHTARG = mytype,
      PROCEDURE = mytype_eq,
      COMMUTATOR = '=',
      NEGATOR = '<>',
      RESTRICT = eqsel,
      JOIN = eqjoinsel,
      HASHES, MERGES
    );

    CREATE OPERATOR <> (
      LEFTARG = mytype,
      RIGHTARG = mytype,
      PROCEDURE = mytype_ne,
      COMMUTATOR = '<>',
      NEGATOR = '=',
      RESTRICT = neqsel,
      JOIN = neqjoinsel
    );

    CREATE OPERATOR < (
      LEFTARG = mytype,
      RIGHTARG = mytype,
      PROCEDURE = mytype_lt,
      COMMUTATOR = > ,
      NEGATOR = >= ,
      RESTRICT = scalarltsel,
      JOIN = scalarltjoinsel
    );

    CREATE OPERATOR <= (
      LEFTARG = mytype,
      RIGHTARG = mytype,
      PROCEDURE = mytype_le,
      COMMUTATOR = >= ,
      NEGATOR = > ,
      RESTRICT = scalarltsel,
      JOIN = scalarltjoinsel
    );

    CREATE OPERATOR > (
      LEFTARG = mytype,
      RIGHTARG = mytype,
      PROCEDURE = mytype_gt,
      COMMUTATOR = < ,
      NEGATOR = <= ,
      RESTRICT = scalargtsel,
      JOIN = scalargtjoinsel
    );

    CREATE OPERATOR >= (
      LEFTARG = mytype,
      RIGHTARG = mytype,
      PROCEDURE = mytype_ge,
      COMMUTATOR = <= ,
      NEGATOR = < ,
      RESTRICT = scalargtsel,
      JOIN = scalargtjoinsel
    );

    CREATE OPERATOR CLASS btree_mytype_ops
    DEFAULT FOR TYPE mytype USING btree
    AS
            OPERATOR        1       <  ,
            OPERATOR        2       <= ,
            OPERATOR        3       =  ,
            OPERATOR        4       >= ,
            OPERATOR        5       >  ,
            FUNCTION        1       mytype_cmp(mytype, mytype);

    CREATE OPERATOR CLASS hash_mytype_ops
        DEFAULT FOR TYPE mytype USING hash AS
            OPERATOR        1       = ,
            FUNCTION        1       hash_mytype(mytype);

## References

* [Writing extensions](http://big-elephants.com/2015-10/writing-postgres-extensions-part-ii/)
* [Operator classes explained](http://www.cybertec.at/2013/11/operator-classes-explained/)