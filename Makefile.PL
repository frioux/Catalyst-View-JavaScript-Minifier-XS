use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::View::JavaScript::Minifier::XS',
    AUTHOR              => 'Ivan Drinchev <drinchev@gmail.com>',
    VERSION_FROM        => 'lib/Catalyst/View/JavaScript/Minifier/XS.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/View/JavaScript/Minifier/XS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'CSS::Minifier::XS' => 0,
		'CSS::Squish' => 0,
		'Catalyst' => 5.64		
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-View-JavaScript-Minifier-XS-*' },
);
