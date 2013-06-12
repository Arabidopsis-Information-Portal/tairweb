use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Geo::IP::PurePerl',
    'VERSION_FROM' => 'lib/Geo/IP/PurePerl.pm', # finds $VERSION
    'EXE_FILES' => ['geoip-lookup'],
);
