package Org::MultiParser;

use 5.010001;
use Moo;

use Org::MultiDocument;
use Org::Parser;
use Scalar::Util qw(blessed);

# VERSION


# ABSTRACT: Parse Org documents
=head1 SYNOPSIS

 use 5.010;
 use Org::MultiParser;
 my $orgp = Org::Parser->new();

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=cut


sub parse {
    my ($self, $arg, $opts) = @_;
    die "Please specify a defined argument to parse()\n" unless defined($arg);

    my $m = Org::MultiDocument->new();

    foreach my $f (keys %$arg)
    {
        $m->add($f, Org::Parser->parse($arg->{$f}, $opts));
    }
    return $m;
}

sub parse_files {
    my ($self, $arg, $opts) = @_;
    die "Please specify a defined argument to parse()\n" unless defined($arg);

    my $m = Org::MultiDocument->new();

    foreach my $f (keys %$arg)
    {
        $m->add($f, Org::Parser->parse_file($arg->{$f}, $opts));
    }
    return $m;
}

=head1 SEE ALSO

L<Org::Parser>
L<Org::MultiDocument>

=cut

1;
