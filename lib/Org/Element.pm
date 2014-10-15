package Org::Element;

use 5.010;
use locale;
use Log::Any '$log';
use Moo;
use Scalar::Util qw(refaddr reftype);

# VERSION

has document => (is => 'rw');
has parent => (is => 'rw');
has children => (is => 'rw');

# store the raw string (to preserve original formatting), not all elements use
# this, usually only more complex elements
has _str => (is => 'rw');
has _str_include_children => (is => 'rw');

sub children_as_string {
    my ($self) = @_;
    return "" unless $self->children;
    join "", map {$_->as_string} @{$self->children};
}

sub as_string {
    my ($self) = @_;

    if (defined $self->_str) {
        return $self->_str .
            ($self->_str_include_children ? "" : $self->children_as_string);
    } else {
        return "" . $self->children_as_string;
    }
}

sub seniority {
    my ($self) = @_;
    my $c;
    return -4 unless $self->parent && ($c = $self->parent->children);
    my $addr = refaddr($self);
    for (my $i=0; $i < @$c; $i++) {
        return $i if refaddr($c->[$i]) == $addr;
    }
    return undef;
}

sub prev_sibling {
    my ($self) = @_;

    my $sen = $self->seniority;
    return undef unless defined($sen) && $sen > 0;
    my $c = $self->parent->children;
    $c->[$sen-1];
}

sub next_sibling {
    my ($self) = @_;

    my $sen = $self->seniority;
    return undef unless defined($sen);
    my $c = $self->parent->children;
    return undef unless $sen < @$c-1;
    $c->[$sen+1];
}

sub extra_walkables { return () }

sub walk {
    my ($self, $code) = @_;
    $code->($self);
    if ($self->children) {
        $_->walk($code) for @{$self->children};
    }
    $_->walk($code) for $self->extra_walkables;
}

sub walktail {
    my ($self, $code) = @_;
    if ($self->children) {
        $_->walk($code) for @{$self->children};
    }
    $_->walk($code) for $self->extra_walkables;
    $code->($self);
}

sub find {
    my ($self, $criteria) = @_;
    return unless $self->children;
    my @res;
    $self->walk(
        sub {
            my $el = shift;
            if (ref($criteria) eq 'CODE') {
                push @res, $el if $criteria->($el);
            } elsif ($criteria =~ /^\w+$/) {
                push @res, $el if $el->isa("Org::Element::$criteria");
            } else {
                push @res, $el if $el->isa($criteria);
            }
        });
    @res;
}

sub walk_parents {
    my ($self, $code) = @_;
    my $parent = $self->parent;
    while ($parent) {
        return $parent unless $code->($self, $parent);
        $parent = $parent->parent;
    }
    return;
}

sub headline {
    my ($self) = @_;
    my $h;
    $self->walk_parents(
        sub {
            my ($el, $p) = @_;
            if ($p->isa('Org::Element::Headline')) {
                $h = $p;
                return;
            }
            1;
        });
    $h;
}

sub headpath {
    my ($self) = @_;
    my @path;
    $self->walk_parents(
        sub {
            my ($el, $p) = @_;
            if ($p->isa('Org::Element::Headline')) {
                unshift @path, $p;
            }
            1;
        });
    # include the given headline, if it is a headline
    push @path, $self if $self->isa("Org::Element::Headline");
    return @path;
}

sub findpath {
    my ($self, @path) = @_;
    # if given a array ref, turn it into an array
    @path = @{$path[0]} if $#path == 0 and ref $path[0] eq "ARRAY";

    my $searchroot = $self;
    foreach my $i (@path)
    {
        # no children!
        return undef unless ref $searchroot->children eq "ARRAY";

        # locate the child at this point in the path
        ($searchroot) = grep(
            (ref $i ?
             $i eq $_ :
             $i eq $_->title->as_string),
            @{$searchroot->children});
        next if $searchroot;

        # this is not the node you're looking for
        return undef;
    }
    return $searchroot;
}

sub field_name {
    my ($self) = @_;

    my $prev = $self->prev_sibling;
    if ($prev && $prev->isa('Org::Element::Text')) {
        my $text = $prev->as_string;
        if ($text =~ /(?:\A|\R)\s*(.+?)\s*:\s*\z/) {
            return $1;
        }
    }
    my $parent = $self->parent;
    if ($parent && $parent->isa('Org::Element::ListItem')) {
        my $list = $parent->parent;
        if ($list->type eq 'D') {
            return $parent->desc_term->as_string;
        }
    }
    # TODO
    #if ($parent && $parent->isa('Org::Element::Drawer') &&
    #        $parent->name eq 'PROPERTIES') {
    #}
    return;
}

sub remove {
    my ($self) = @_;
    my $parent = $self->parent;
    return unless $parent;
    splice @{$parent->children}, $self->seniority, 1;
}

1;
# ABSTRACT: Base class for Org document elements

=head1 SYNOPSIS

 # Don't use directly, use the other Org::Element::* classes.


=head1 DESCRIPTION

This is the base class for all the other Org element classes.


=head1 ATTRIBUTES

=head2 document => DOCUMENT

Link to document object. Elements need this to access file-wide settings,
properties, etc.

=head2 parent => undef | ELEMENT

Link to parent element. Undef if this element is the root element.

=head2 children => undef | ARRAY_OF_ELEMENTS


=head1 METHODS

=head2 $el->children_as_string() => STR

Return a concatenation of children's as_string(), or "" if there are no
children.

=head2 $el->as_string() => STR

Return the string representation of element. The default implementation will
just use _str (if defined) concatenated with children_as_string().

=head2 $el->seniority => INT

Find out the ranking of brothers/sisters of all sibling. If we are the first
child of parent, return 0. If we are the second child, return 1, and so on.

=head2 $el->prev_sibling() => ELEMENT | undef

=head2 $el->next_sibling() => ELEMENT | undef

=head2 $el->extra_walkables => LIST

Return extra walkable elements. The default is to return an empty list, but some
elements can have this, for L<Org::Element::Headline>'s title is also a walkable
element.

=head2 $el->walk(CODEREF)

Call CODEREF for node and all descendent nodes (and extra walkables),
depth-first. Code will be given the element object as argument.

=head2 $el->find(CRITERIA) => ELEMENTS

Find subelements. CRITERIA can be a word (e.g. 'Headline' meaning of class
'Org::Element::Headline') or a class name ('Org::Element::ListItem') or a
coderef (which will be given the element to test). Will return matched elements.

=head2 $el->walk_parents(CODE)

Run CODEREF for parent, and its parent, and so on until the root element (the
document), or until CODEREF returns a false value. CODEREF will be supplied
($el, $parent). Will return the last parent walked.

=head2 $el->headline() => ELEMENT

Get current headline.

=head2 $el->headpath() => ARRAY of ELEMENT

Get the path of Org::Element::Headline objects to this element.
For example, given this org file:
 * foo
 ** bar
 *** baz
 text

Running headpath() on "text" or on the "baz" headline will return the elements "foo", "bar" and "baz" in that order.

=head2 $el->findpath(ARRAY) => ELEMENT

Return the headline at the given path.  Given the example org file shown
for headpath() (q.v.), findpath(qw(foo bar baz)) would return the element
object for "baz".

If there is no such path undef will be returned.

=head2 $el->field_name() => STR

Try to extract "field name", being defined as either some text on the left side:

 DEADLINE: <2011-06-09 >

or a description term in a description list:

 - wedding anniversary :: <2011-06-10 >

=head2 $el->remove()

Remove element from the tree. Basically just remove the element from its parent.

=cut
