package CGI::Upload::Test;
use strict;
use base 'Exporter';
use vars qw(@EXPORT);
@EXPORT = qw(&upload_file);

use Test::More;

# subroutine to upload any file (and prepare the multi-part version of it on the fly).
# For some reason you cannot run this function twice !?? What bug is this ?
# using local/plain.txt

use CGI::Upload;

sub upload_file {
	my $original_file = shift;
	my $args = shift || {};
	
	my $long_filename_on_client = $args->{long_filename_on_client} || $original_file;
	my $short_filename_on_client = $args->{short_filename_on_client} || $original_file;
	
	

	my $boundary = "----------9GN0yM260jGW3Pq48BILfC";

	open FH, "<", "local/$original_file" or die "Cannot open local/$original_file\n";
	my $original_content;
	my $original_size = read FH, $original_content, 10000;

	my $original ="";
	$original .= qq(--$boundary\r\n); 
	$original .= qq(Content-Disposition: form-data; name="field"; filename="$long_filename_on_client"\r\n);
	$original .= qq(Content-Type: text/plain\r\n\r\n);
	$original .= qq($original_content\r\n);
	$original .= qq(--$boundary--\r\n);

	local $ENV{REQUEST_METHOD} = "POST";
	local $ENV{CONTENT_LENGTH} = length $original;
	local $ENV{CONTENT_TYPE}   = qq(multipart/form-data; boundary=$boundary);

	my $u;
	my $uploaded_content;
	my $uploaded_size;
	{
		local *STDIN;
		open STDIN, "<", \$original;
		#binmode(STDIN);

		$u = CGI::Upload->new();
		my $remote = $u->file_handle('field');
		$uploaded_size = read $remote, $uploaded_content, 10000;
	}
	is($u->file_name("field"), $short_filename_on_client, "filename '$short_filename_on_client' is correct");

	is($uploaded_size, $original_size, "size is correct");
	is($uploaded_content, $original_content, "Content is the same");

	# we might not need to test the following failors in every call, but on the other hand, why not ?
	eval {
		$u->invalid_call()
	};
	like($@, qr{CGI::Upload->AUTOLOAD : Unsupported object method within module - invalid_call}, "Invalid call trapped");
	ok(not(defined $u->file_name("other_field")), "returns undef");
}

1;


