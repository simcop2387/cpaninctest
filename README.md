This is a simple hacky script that uses perlbrew and cpanm to test modules against ```perl $ENV{PERL_USE_UNSAFE_INC}``` to see if they fail.  It does this by re-implementing the dependency search for the modules.

This script is inteded to be used to test if your current project or module needs '.' in @INC.  I've built it towards that goal for perlbot and it's eval so I can file bugs with all relavent modules.

To test, i recommend installing blead via perlbrew.  ```perlbrew install blead```

it will litter some files:
	modcache.stor
	logs/*.log

these can be removed after you're done, but keeping the .stor file means that it won't re-fetch dependency lists off cpan.

The logs are failure logs, *_incfailure.log are ones that failed due to @INC, and *_genfailure.log are ones that failed due to some other kind of problem (missing library, etc.)
