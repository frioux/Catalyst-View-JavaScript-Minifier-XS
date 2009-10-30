package Catalyst::Helper::View::JavaScript::Minifier::XS;

use strict;
use warnings;

=head1 NAME

Catalyst::Helper::View::JavaScript::Minifier::XS - Helper for JavaScript::Minifier::XS views

=head1 SYNOPSIS

 script/create.pl view JavaScript JavaScript::Minifier::XS

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
}

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;

use parent 'Catalyst::View::JavaScript::Minifier::XS';

1;
