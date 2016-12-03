#!perl6
use v6;
use Test;
use JSON::Unmarshal;

subtest {
    class VersionClassCode {
        has Version $.version is unmarshalled-by(-> $v { Version.new($v) });
    }

    my $json = '{ "version" : "0.0.1" }';

    my VersionClassCode $obj;

    lives-ok { $obj = unmarshal($json, VersionClassCode) }, "unmarshall with attrbute strait (code)";
    isa-ok $obj.version, Version, "the attribute is the right kind of thing";
    ok $obj.version.defined, "and it's defined";
    is $obj.version, Version.new("0.0.1"), "and has the right value";
}, "unmarshalled-by trait with Code";
subtest {
    class VersionClassMethod {
        has Version $.version is unmarshalled-by('new');
    }

    my $json = '{ "version" : "0.0.1" }';

    my VersionClassMethod $obj;

    lives-ok { $obj = unmarshal($json, VersionClassMethod) }, "unmarshall with attrbute trait (method name)";
    isa-ok $obj.version, Version, "the attribute is the right kind of thing";
    ok $obj.version.defined, "and it's defined";
    is $obj.version, Version.new("0.0.1"), "and has the right value";
}, "unmarshalled-by trait with Method name";
subtest {
    class CustomArrayAttribute {
        class Inner {
            has Str $.name is required;
        }

        sub unmarshall-inners (@inners) {
            @inners.map(-> $name { Inner.new(:$name) })
        }

        has Inner @.inners is unmarshalled-by(&unmarshall-inners);
    }

    my $json = '{ "inners" : [ "one", "two", "three" ] }';
    my $obj;
    lives-ok {
        $obj = unmarshal $json, CustomArrayAttribute;
    }, "unmarshal with custom marshaller on positional attribute";

    ok all($obj.inners) ~~ CustomArrayAttribute::Inner, "and all the objects in the array are correct";
    is-deeply $obj.inners.map( *.name), <one two three>, "and they have their names set correctly";


}, "unmarshalled-by on a positional attribute";

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
