unit module JSON::Unmarshal;
use JSON::Tiny;

sub panic($json, $type) {
    die "Cannot unmarshal {$json.perl} to type {$type.perl}"
}

multi _unmarshal($json, Int) {
    if $json ~~ Int {
        return Int($json)
    }
    panic($json, Int)
}

multi _unmarshal($json, Rat) {
   CATCH {
      default {
         panic($json, Rat);
      }
   }
   return Rat($json);
}

multi _unmarshal($json, Numeric) {
    if $json ~~ Numeric {
        return Num($json)
    }
    panic($json, Numeric)
}

multi _unmarshal($json, Str) {
    if $json ~~ Stringy {
        return Str($json)
    }
}

multi _unmarshal($json, Bool) {
   CATCH {
      default {
         panic($json, Bool);
      }
   }
   return Bool($json);
}

multi _unmarshal($json, Any $x) {
    my %args;
    for $x.^attributes -> $attr {
        my $name = $attr.name.substr(2);
        %args{$name} = _unmarshal($json{$name}, $attr.type);
    }
    return $x.new(|%args)
}

multi _unmarshal($json, @x) {
    my @ret;
    for $json.list -> $value {
       my $type = @x.of =:= Any ?? $value.WHAT !! @x.of;
       @ret.push(_unmarshal($value, $type));
    }
    return @ret
}

multi _unmarshal($json, %x) {
   my %ret;
   for $json.kv -> $key, $value {
      my $type = %x.of =:= Any ?? $value.WHAT !! %x.of;
      %ret{$key} = _unmarshal($value, $type);
   }
   return %ret;
}

multi _unmarshal($json, Mu) {
    return $json
}

sub unmarshal($json, $obj) is export {
    _unmarshal(from-json($json), $obj)
}
