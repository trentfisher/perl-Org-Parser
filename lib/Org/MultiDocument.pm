package Org::MultiDocument;

use 5.010001;
use Moo;

use Org::Document;
use Org::Parser;
use Scalar::Util qw(blessed);

# VERSION

# ABSTRACT: Parse Org documents
=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=cut

sub add {
    my ($self, $name, $doc) = @_;
    $self->{doc}{$name} = $doc;
    $self->{tree} = {} unless $self->{tree};
    $self->_buildtree($name, $doc, $self);
}

sub _buildtree {
    my ($self, $name, $el, $ret) = @_;
    my $title;
    if ($el->isa('Org::Element::Headline')) {
        $title = $el->title->as_string;
    }
    elsif ($el->isa('Org::Document')) {
        $title = "tree"
    }
    else { return }
    $ret->{$title}{title} = $title;
    $ret->{$title}{elems}{$name} = $el;

    foreach my $c ($el->children ? @{$el->children} : ()) {
        next unless $c->isa('Org::Element::Headline');
        $ret->{$title}{child} = {} unless $ret->{$title}{child};
        $self->_buildtree($name, $c,
                          $ret->{$title}{child});
    }
}

sub headwalk {
    my ($self, $code, $r) = @_;
    if ($r) {
        $code->($r->{title}, $r->{elems});
    } else {
        $r = $self->{tree};
    }
    foreach my $c (sort keys %{$r->{child}}) {
        $self->headwalk($code, $r->{child}{$c});
    }
}


=head1 SEE ALSO

L<Org::Document>
L<Org::MultiDocument>

=cut

1;
