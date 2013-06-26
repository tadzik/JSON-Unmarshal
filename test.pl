use lib 'lib';
use JSON::Unmarshal;

class Dog {
    has Str $.name;
    has Str $.race;
    has Int $.age;
}

class Person {
    has Str $.name;
    has Int $.age;
    has Dog $.dog;
}

my $json = q/
{
    "name" : "John Brown",
    "age"  : 17,
    "dog"  : {
        "name" : "Roger",
        "race" : "corgi",
        "age"  : 4
    }
}
/;

my $p = unmarshal($json, Person);
say $p.perl;
