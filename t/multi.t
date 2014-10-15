#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Org::MultiParser;
use Test::Exception;
use Test::More 0.96;
require "testlib.pl";
use Data::Dumper;

my $doc1 = <<_;
* test1
** test11
* test2
_

my $doc2 = <<_;
* test1
** test12
* test2
_

my $doc3 = <<_;
* test1
** test11
* test3
_

my $orgp = Org::MultiParser->new();
my $docs = $orgp->parse({doc1 => $doc1,
                         doc2 => $doc2,
                         doc3 => $doc3});
ok($docs);

#print Dumper([$docs->{tree}]);

$docs->headwalk(sub {
    my ($title, $el) = @_;
    my $d = $el->{(keys %$el)[0]}->level;
    printf("%s %s (%s)\n", "*"x$d, $title, join(",", sort keys %$el));
});


done_testing();
exit 0;
