use v6;
unit module JSON::Unmarshal;
use JSON::Name;
use JSON::Fast;

=begin pod
=NAME JSON::Unmarshal

Make JSON from an Object (the opposite of JSON::Marshal)

=SYNOPSIS

    use JSON::Unmarshal;

    class SomeClass {
        has Str $.string;
        has Int $.int;
    }

    my $json = '{ "string" : "string", "int" : 42 }';

    my SomeClass $object = unmarshal($json, SomeClass);

    say $object.string; # -> "string"
    say $object.int;    # -> 42


It is also possible to use a trait to control how the value is unmarshalled:

    use JSON::Unmarshal

    class SomeClass {
        has Version $.version is unmarshalled-by(-> $v { Version.new($v) });
    }

    my $json = '{ "version" : "0.0.1" }';

    my SomeClass $object = unmarshal($json, SomeClass);

    say $object.version; # -> "v0.0.1"


The trait has two variants, one which takes a Routine as above, the other
a Str representing the name of a method that will be called on the type
object of the attribute type (such as "new",) both are expected to take
the value from the JSON as a single argument.

=DESCRIPTION

This provides a single exported subroutine to create an object from a
JSON representation of an object.

It only initialises the "public" attributes (that is those with accessors
created by declaring them with the '.' twigil. Attributes without acccessors
are ignored.

=INSTALLATION

Assuming you have a working Raku installation you should be able to
install this with *zef* :

=begin code
# From the source directory

zef install .

# Remote installation

zef install JSON::Unmarshal
=end code

=SUPPORT

Suggestions/patches are welcomed via github at

L<https://github.com/raku-community-modules/JSON-Unmarshal>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2017 Tadeusz Sośnierz
Copyright 2022 Raku Community

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

Please see the LICENCE file in the distribution

=end pod

our class X::CannotUnmarshal is Exception is export {
    has Attribute:D $.attribute is required;
    has Any:D $.json is required;
    has Mu:U $.type is required;
    has Mu:U $.target is required;
    has Str $.why;
    method message {
        "Cannot unmarshal {$.json.raku} into type '{$.type.^name}' for attribute {$.attribute.name} of '{$.target.^name}'"
        ~ ($.why andthen ": $_" orelse "")
    }
}

role CustomUnmarshaller {
    method unmarshal($value, Mu:U $type) {
        ...
    }
}

role CustomUnmarshallerCode does CustomUnmarshaller {
    has &.unmarshaller is rw;

    method unmarshal($value, Mu:U $) {
        # the dot below is important otherwise it refers
        # to the accessor method
        self.unmarshaller.($value);
    }
}

role CustomUnmarshallerMethod does CustomUnmarshaller {
    has Str $.unmarshaller is rw;
    method unmarshal($value, Mu:U $type) {
        my $meth = self.unmarshaller;
        $type."$meth"($value);
    }
}

multi sub trait_mod:<is> (Attribute $attr, :&unmarshalled-by!) is export {
    $attr does CustomUnmarshallerCode;
    $attr.unmarshaller = &unmarshalled-by;
}

multi sub trait_mod:<is> (Attribute $attr, Str:D :$unmarshalled-by!) is export {
    $attr does CustomUnmarshallerMethod;
    $attr.unmarshaller = $unmarshalled-by;
}

proto sub panic(Any, Mu, |) {*}
multi sub panic($json, Mu \type, X::CannotUnmarshal:D $ex) {
    $ex.rethrow
}
multi sub panic($json, Mu \type, Exception:D $ex) {
    samewith($json, type, $ex.message)
}
multi sub panic($json, Mu \type, Str $why?) {
    X::CannotUnmarshal.new(
        :$json,
        :type(type.WHAT),
        :attribute($*JSON-UNMARSHAL-ATTR),
        :$why,
        :target($*JSON-UNMARSHAL-TYPE) ).throw
}

multi _unmarshal(Any:U, Mu $type) {
    $type;
}

multi _unmarshal(Any:D $json, Int) {
    if $json ~~ Int {
        return Int($json)
    }
    panic($json, Int)
}

multi _unmarshal(Any:D $json, Rat) {
   CATCH {
      default {
         panic($json, Rat, $_);
      }
   }
   return Rat($json);
}

multi _unmarshal(Any:D $json, Numeric) {
    if $json ~~ Numeric {
        return Num($json)
    }
    panic($json, Numeric)
}

multi _unmarshal($json, Str) {
    if $json ~~ Stringy {
        return Str($json)
    }
    else {
        Str;
    }
}

multi _unmarshal(Any:D $json, Bool) {
   CATCH {
      default {
         panic($json, Bool, $_);
      }
   }
   return Bool($json);
}

multi _unmarshal(Any:D $json, Any $obj is raw) {
    my %args;
    my \type = $obj.HOW.archetypes.nominalizable ?? $obj.^nominalize !! $obj.WHAT;
    my %local-attrs =  type.^attributes(:local).map({ $_.name => $_.package });
    for type.^attributes -> $attr {
        my $*JSON-UNMARSHAL-ATTR = $attr;
        if %local-attrs{$attr.name}:exists && !(%local-attrs{$attr.name} === $attr.package ) {
            next;
        }
        my $attr-name = $attr.name.substr(2);
        my $json-name = do if  $attr ~~ JSON::Name::NamedAttribute {
            $attr.json-name;
        }
        else {
            $attr-name;
        }
        if $json{$json-name}:exists {
            my Mu $attr-type := $attr.type;
            %args{$attr-name} := do if $attr ~~ CustomUnmarshaller {
                $attr.unmarshal($json{$json-name}, $attr-type)
            }
            elsif $attr-type.HOW.archetypes.nominalizable
                && $attr-type.HOW.archetypes.coercive
                && $json{$json-name} ~~ $attr-type
            {
                # No need to unmarshal, coercion will take care of it
                $json{$json-name}
            }
            else {
                _unmarshal($json{$json-name}, $attr-type)
            }
        }
    }
    type.new(|%args)
}

multi _unmarshal($json, @x) {
    my @ret := Array[@x.of].new;
    for $json.list -> $value {
       my $type = @x.of =:= Any ?? $value.WHAT !! @x.of;
       @ret.append(_unmarshal($value, $type));
    }
    return @ret;
}

multi _unmarshal($json, %x) {
   my %ret := Hash[%x.of].new;
   for $json.kv -> $key, $value {
      my $type = %x.of =:= Any ?? $value.WHAT !! %x.of;
      %ret{$key} = _unmarshal($value, $type);
   }
   return %ret;
}

multi _unmarshal(Any:D $json, Mu) {
    return $json
}

proto unmarshal(Any:D, |) is export {*}

multi unmarshal(Str:D $json, Positional $obj) {
    my $*JSON-UNMARSHAL-TYPE := $obj.WHAT;
    my Any \data = from-json($json);
    if data ~~ Positional {
        return @(_unmarshal($_, $obj.of) for @(data));
    } else {
        fail "Unmarshaling to type $obj.^name() requires the json data to be a list of objects.";
    }
}

multi unmarshal(Str:D $json, Associative $obj) {
    my $*JSON-UNMARSHAL-TYPE := $obj.WHAT;
    my \data = from-json($json);
    if data ~~ Associative {
        return %(for data.kv -> $key, $value {
            $key => _unmarshal($value, $obj.of)
        })
    } else {
        fail "Unmarshaling to type $obj.^name() requires the json data to be an object.";
    };
}

multi unmarshal(Str:D $json, $obj) {
    my $*JSON-UNMARSHAL-TYPE := $obj.WHAT;
    _unmarshal(from-json($json), $obj.WHAT)
}

multi unmarshal(%json, $obj) {
    my $*JSON-UNMARSHAL-TYPE := $obj.WHAT;
    _unmarshal(%json, $obj.WHAT)
}

multi unmarshal(@json, $obj) {
    my $*JSON-UNMARSHAL-TYPE := $obj.WHAT;
    _unmarshal(@json, $obj.WHAT)
}
# vim: expandtab shiftwidth=4 ft=raku
