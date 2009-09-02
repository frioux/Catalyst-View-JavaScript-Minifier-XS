#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Catalyst::View::JavaScript::Minifier::XS' );
}

diag( "Testing Catalyst::View::JavaScript::Minifier::XS $Catalyst::View::JavaScript::Minifier::XS::VERSION, Perl $], $^X" );
