---
layout: post
title:  "A simple example to demo custom data type and operator class"
author: Pivotal Engineer
date:   2016-11-09 23:00 +0800
categories: gpdb operator class
published: true
---

# An example for user defined type and operator class

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