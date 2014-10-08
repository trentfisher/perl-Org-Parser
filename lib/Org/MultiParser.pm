package Org::MultiParser;

use 5.010001;
use Moo;

use File::Slurp::Tiny qw(read_file);
use Org::Document;
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

=cut

sub parse {
    my ($self, $arg, $opts) = @_;
    die "Please specify a defined argument to parse()\n" unless defined($arg);

    my $m = {}; #Org::MultiDocument->new()

    foreach my $f (keys %$arg)
    {
        $m->{$f} = Org::Parser->parse($arg->{$f});
    }
    return $m;
}

=head1 METHODS

=head1 SEE ALSO

L<Org::Document>

=cut

1;
