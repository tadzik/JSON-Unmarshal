#!raku

use v6;
use Test;

use JSON::Unmarshal;

sub test-typed($json, Mu \obj-class, Mu $expected, Str :$message is copy, Bool :$is-null) {
    my $type-name = $expected.^name;
    my $ret;
    $message //= "$type-name attribute from " ~ ($json ~~ Str ?? "JSON string" !! "a " ~ $json.^name);
    subtest $message => {
        plan 4;
        lives-ok { $ret = unmarshal($json, obj-class) }, "unmarshal with $type-name typed attribute";
        isa-ok $ret, obj-class.WHAT, "it's the right object type";
        if $is-null {
            nok $ret.attr.defined, "and unefined";
            isa-ok $ret.attr, $expected.WHAT, "and the correct type";
        }
        else {
            ok $ret.attr.defined, "and defined";
            is $ret.attr, $expected, "and the correct value";
        }
        done-testing;
    }
}

class RatClass {
    has $.attr;
}
class NumClass {
    has Num $.attr;
}
class IntClass {
    has Int $.attr;
}
class BoolClass {
    has Bool $.attr;
}
class StrClass {
    has Str $.attr;
}

my @tests =
    [
        '{ "attr" : 4.2 }',
        RatClass,
        4.2,
    ],
    [
        '{ "attr" : 4.2 }',
        NumClass,
        4.2,
    ],
    [
        '{ "attr" : 42 }',
        IntClass,
        42,
    ],
    [
        '{ "attr" : true }',
        BoolClass,
        True,
    ],
    [
        '{ "attr" : false }',
        BoolClass,
        False,
        :message("Bool attribute with False")
    ],
    [
        '{ "attr" : "foo" }',
        StrClass,
        "foo",
    ],
    [
        '{ "attr" : null }',
        StrClass,
        Str,
        message => "Str attribute with 'null' in JSON",
        :is-null,
    ],
    [
        { attr => 4.2 },
        RatClass,
        4.2,
    ],
    [
        { attr => 4.2 },
        NumClass,
        4.2,
    ],
    [
        { attr => 42 },
        IntClass,
        42,
    ],
    [
        { attr => True },
        BoolClass,
        True,
    ],
    [
        { attr => False },
        BoolClass,
        False,
        :message("Bool attribute with False in JSON hash")
    ],
    [
        { attr => "foo" },
        StrClass,
        "foo",
    ],
    [
        { attr => Nil },
        StrClass,
        Str,
        message => "Str attribute with Nil in JSON hash",
        :is-null,
    ],
    ;

plan +@tests;

for @tests -> @test {
    my @pos = @test.grep( * !~~ Pair );
    my %named = |@test.grep( * ~~ Pair );
    test-typed |@pos, |%named;
}

done-testing;

# vim: expandtab shiftwidth=4 ft=perl6
