#!/usr/bin/env raku

use Test;
use JSON::Unmarshal;
use JSON::OptIn;
use JSON::Name;

class OptInClass {

    has Str $.not_opted_in = "original";
    has Str $.opted_in     is json;
}

my $json = '{ "not_opted_in" : "not original", "opted_in" : "something" }';

my $obj;

lives-ok { $obj = unmarshal($json, OptInClass, :opt-in) }, 'unmarshal with opt-in';

is $obj.not_opted_in, 'original', "attribute not marked explicitly not populated from JSON";
is $obj.opted_in, 'something', "attribute marked is set";

done-testing;
# vim: ft=raku
