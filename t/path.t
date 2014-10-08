#!perl
#
# test newly added path routines

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Org::Parser;
use Test::Exception;
use Test::More 0.96;
require "testlib.pl";


test_parse(
    name => 'headpath tests',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
** h1
*** h2
**** h3
*** h4
** h5
text
_
    num => 5,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        my ($h1, $h2, $h3, $h4, $h5) = @$elems;

        # check that we can get the path for each headline
        my @p = $h1->headpath;
        print join(" -> ", map($_->title->as_string, @p)),"\n";
        is($#p, 0);

        @p = $h2->headpath;
        print join(" -> ", map($_->title->as_string, @p)),"\n";
        is($#p, 1);

        @p = $h3->headpath;
        print join(" -> ", map($_->title->as_string, @p)),"\n";
        is($#p, 2);

        @p = $h4->headpath;
        print join(" -> ", map($_->title->as_string, @p)),"\n";
        is($#p, 1);

        @p = $h5->headpath;
        print join(" -> ", map($_->title->as_string, @p)),"\n";
        is($#p, 0);

        # check that querying text nodes works too
        my @p2 = $h5->children->[0]->headpath;
        is_deeply(\@p2, \@p, "make sure path is the same for text nodes");

        # findpath tests
        my $res = $args{result};
        my $e = $res->findpath(qw(h1));
        is($e, $h1);

        $e = $res->findpath(qw(h1 h2));
        is($e, $h2);

        $e = $res->findpath(qw(h1 h2 h3));
        is($e, $h3);

        $e = $res->findpath(qw(h1 h4));
        is($e, $h4);

        $e = $res->findpath(qw(h5));
        is($e, $h5);


        # now combine the two
        $e = $res->findpath(qw(h1 h2 h3));
        is($e, $h3);
        @p = $e->headpath;
        is($#p, 2);
        is($p[0]->title->as_string, "h1");
        is($p[1]->title->as_string, "h2");
        is($p[2]->title->as_string, "h3");
    });

done_testing();
