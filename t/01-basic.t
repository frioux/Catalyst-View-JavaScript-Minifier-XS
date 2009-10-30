#!perl

use strict;
use warnings;

use FindBin;
use Test::More;
use File::Spec;
use JavaScript::Minifier::XS 'minify';

use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp';

my $served = get('/test');

ok $served, q{served data isn't blank};
my $path = File::Spec->catfile($FindBin::Bin, qw{lib TestApp root js foo.js});
open my $file, '<', $path;

my $str = q{};
while (<$file>) {
   $str .= $_;
}

is minify($str), $served, 'server actually minifed the javascript, so we know that changing the stash variable and path worked';

done_testing;

