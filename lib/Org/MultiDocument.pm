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
        # apparently headlines can have trailing white space
        $title =~ s/\s*$//;
        $title =~ s/^\s*//;
    }
    elsif ($el->isa('Org::Document')) {
        $title = "tree"
    }
    else { return }

    if ($ret->{$title}{elems}{$name})
    {
        warn "Error: duplicate definition of $title in $name, skipping\n";
        return;
    }

    $ret->{$title}{title} = $title;
    $ret->{$title}{elems}{$name} = $el;
    $ret->{$title}{seniority} += $el->seniority;

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
        $code->($r->{title}, $r->{elems},
                $r->{elems}->{(keys %{$r->{elems}})[0]}->level);
    } else {
        $r = $self->{tree};
    }
    foreach my $c (sort {$r->{child}{$a}{seniority} <=>
                         $r->{child}{$b}{seniority} }
                   keys %{$r->{child}}) {
        $self->headwalk($code, $r->{child}{$c});
    }
}

sub check {
    my $self = shift;

    $self->headwalk(sub {
        my ($title, $el, $d) = @_;
        foreach my $name (sort keys %{$el})
        {
            next unless ref $el->{$name};
            if (ref($el->{$name}) !~ /Org::/)
            {
                warn "something wrong at $name $title\n";
                next;
            }
            my @p = $el->{$name}->headpath();
            my $oel = $self->{doc}{$name}->findpath(@p) || "";
            #print "checking $name $title $el->{$name} vs $oel\n";
            warn("different elements for $name at @p\n")
                if $el->{$name} ne $oel;
        }
    });
}

=head1 SEE ALSO

L<Org::Document>
L<Org::MultiDocument>

=cut

1;
