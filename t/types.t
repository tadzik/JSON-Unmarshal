#!perl6

use v6;
use Test;

use JSON::Unmarshal;

subtest {
    my class RatClass {
        has Rat $.rat;
    }

    my $json = '{ "rat" : 4.2 }';
    my $ret;

    lives-ok { $ret = unmarshal($json, RatClass) }, "unmarshal with Rat typed attribute";
    isa-ok $ret, RatClass, "it's the right type";
    is $ret.rat, 4.2, "and the correct value";

}, "Rat attribute";
subtest {
    my class NumClass {
        has Num $.num;
    }

    my $json = '{ "num" : 4.2 }';
    my $ret;

    lives-ok { $ret = unmarshal($json, NumClass) }, "unmarshal with Num typed attribute";
    isa-ok $ret, NumClass, "it's the right type";
    is $ret.num, 4.2, "and the correct value";

}, "Num attribute";
subtest {
    my class IntClass {
        has Int $.int;
    }

    my $json = '{ "int" : 42 }';
    my $json2 = '{ "int" : "42"}';
    my $ret;

    lives-ok { $ret = unmarshal($json, IntClass) }, "unmarshal with Int typed attribute";
    isa-ok $ret, IntClass, "it's the right type";
    is $ret.int, 42, "and the correct value";
    lives-ok { $ret = unmarshal($json2, IntClass) }, "unmarshal with Int typed attribute but IntStr json";
    isa-ok $ret, IntClass, "it's the right type";
    is $ret.int, 42, "and the correct value";
    

}, "Int attribute";
subtest {
    my class BoolClass {
        has Bool $.bool;
    }

    my $json = '{ "bool" : true }';
    my $ret;

    lives-ok { $ret = unmarshal($json, BoolClass) }, "unmarshal with Bool typed attribute";
    isa-ok $ret, BoolClass, "it's the right type";
    is $ret.bool, True, "and the correct value";

}, "Bool attribute";
subtest {
    my class StrClass {
        has Str $.string;
    }

    my $json = '{ "string" : null }';
    my $ret;
    lives-ok { $ret = unmarshal($json, StrClass) }, "unmarshal with Str type attribute but null in JSON";
    isa-ok $ret, StrClass, "it's the right type";
    ok $ret.string ~~ Str && !$ret.string.defined, "and it is an undefined Str";
}, "Undefined Str";

done-testing;

# vim: expandtab shiftwidth=4 ft=perl6
