use strict;
use vars qw/ $loaded /;


BEGIN {
    $| = 1;
}


END {
    ok(0) unless $loaded;
}


my $count = 1;
sub ok {
    shift or print "not ";
    print "ok $count\n";
    ++$count;
}


print "1..1\n";

use CGI::Upload;

$loaded = 1;

ok(1);


__END__
