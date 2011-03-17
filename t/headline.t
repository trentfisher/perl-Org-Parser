#!perl

use 5.010;
use strict;
use warnings;

use FindBin '$Bin';
use lib $Bin, "$Bin/t";

use Org::Parser;
use Test::More 0.96;
require "testlib.pl";

test_parse(
    name => 'non-headline (missing space)',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
*h
_
    num => 0,
);

test_parse(
    name => 'non-headline (not on first column)',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
 * h
_
    num => 0,
);

test_parse(
    name => 'non-headline (no title)',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
*
_
    num => 0,
);

test_parse(
    name => 'headline',
    filter_elements => 'Org::Element::Headline',
    doc  => <<'_',
*   h1 1
** h2 1 :tag1:tag2:
*** h3 1
text
*** TODO [#A] h3 2
    text
** DONE h2 2
* h1 2
_
    num => 6,
    test_after_parse => sub {
        my (%args) = @_;
        my $elems = $args{elements};
        is($elems->[0]->title->as_string, "  h1 1", "0: title not trimmed");
        is($elems->[0]->level, 1, "0: level");

        is($elems->[1]->title->as_string, "h2 1", "1: title");
        is($elems->[1]->level, 2, "1: level");
        is_deeply($elems->[1]->tags, ['tag1', 'tag2'], "1: tags");

        is($elems->[2]->title->as_string, "h3 1", "2: title");
        is($elems->[2]->level, 3, "2: level");

        is( $elems->[3]->title->as_string, "h3 2", "3: title");
        is( $elems->[3]->level, 3, "3: level");
        is( $elems->[3]->is_todo, 1, "3: is_todo");
        ok(!$elems->[3]->is_done, "3: is_done");
        is( $elems->[3]->todo_state, "TODO", "3: todo_state");
        is( $elems->[3]->todo_priority, "A", "3: todo_priority");

        is($elems->[4]->title->as_string, "h2 2", "4: title");
        is($elems->[4]->level, 2, "4: level");
        is($elems->[4]->is_todo, 1, "4: is_todo");
        is($elems->[4]->is_done, 1, "4: is_done");
        is($elems->[4]->todo_state, "DONE", "4: todo_state");
        # XXX default priority

        is($elems->[5]->title->as_string, "h1 2", "5: title");
        is($elems->[5]->level, 1, "5: level");
    },
);

done_testing();
