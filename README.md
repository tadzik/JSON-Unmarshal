# JSON::Unmarshal

Make JSON from an Object (the opposite of JSON::Marshal)

## Synopsis

```
    use JSON::Unmarshal;

    class SomeClass {
        has Str $.string;
        has Int $.int;
    }

    my $json = '{ "string" : "string", "int" : 42 }';

    my SomeClass $object = unmarshal($json, SomeClass);

    say $object.string; # -> "string"
    say $object.int;    # -> 42

```

It is also possible to use a trait to control how the value is unmarshalled:

```

    use JSON::Unmarshal

    class SomeClass {
        has Version $.version is unmarshalled-by(-> $v { Version.new($v) });
    }

    my $json = '{ "version" : "0.0.1" }';

    my SomeClass $object = unmarshal($json, SomeClass);

    say $object.version; # -> "v0.0.1"

```

The trait has two variants, one which takes a Routine as above, the other
a Str representing the name of a method that will be called on the type
object of the attribute type (such as "new",) both are expected to take
the value from the JSON as a single argument.

## Description

This provides a single exported subroutine to create an object from a
JSON representation of an object.

It only initialises the "public" attributes (that is those with accessors
created by declaring them with the '.' twigil. Attributes without acccessors
are ignored.

## Installation

Assuming you have a working Raku installation you should be able to
install this with *zef* :

    # From the source directory
   
    zef install .

    # Remote installation

    zef install JSON::Unmarshal

Other install mechanisms may be become available in the future.

## Support

Suggestions/patches are welcomed via github at

    https://github.com/raku-community-modules/JSON-Unmarshal

## Licence

Please see the LICENCE file in the distribution

(C) Tadeusz Sośnierz 2015-2017
(C) Raku Community 2022
