use v6;
unit module JSON::Unmarshal;
use JSON::Name;
use JSON::Fast;

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

    method unmarshal($value, Mu:U $type) {
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

sub panic($json, Mu \type, Str $why?) {
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
         panic($json, Rat);
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
         panic($json, Bool);
      }
   }
   return Bool($json);
}

multi _unmarshal(Any:D $json, Any $x is raw) {
    my %args;
    my %local-attrs =  $x.^attributes(:local).map({ $_.name => $_.package });
    for $x.^attributes -> $attr {
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
    return $x.new(|%args)
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
