use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Postman',
    AUTHOR              => q{Jerome Eteve <jerome.eteve@gmail.com>},
    VERSION_FROM        => 'lib/Email/Postman.pm',
    ABSTRACT_FROM       => 'lib/Email/Postman.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Postman-*' },
);
