use Test::More 'tests' => 2;

BEGIN {

    #   Test 1 - Ensure that the CGI::Upload module can be loaded

    use_ok( 'CGI::Upload' );
}

#   Test 2 - Create a new object and confirm its inheritance as CGI::Upload
#   object

my $object = CGI::Upload->new;
isa_ok( $object, 'CGI::Upload' );
