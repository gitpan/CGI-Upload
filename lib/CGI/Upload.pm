package CGI::Upload;

use Carp;
use CGI;
use File::Basename;
use File::MMagic;
use HTTP::BrowserDetect;
use IO::File;

use strict;
use vars qw/ $AUTOLOAD $VERSION @ISA @EXPORT_OK /;

require Exporter;

@ISA = qw/ Exporter /;
@EXPORT_OK = qw/ file_handle file_name file_type mime_magic mime_type query /;

$VERSION = '1.04';


sub AUTOLOAD {
    my ( $self, $param ) = @_;

    #   Parse method name from $AUTOLOAD variable

    my $property = $AUTOLOAD;
    $property =~ s/.*:://;

    my @properties = qw/ file_handle file_name file_type mime_type /;

    unless ( grep { $property eq $_ } @properties ) {
        croak( __PACKAGE__, '->AUTOLOAD : Unsupported object method within module - ', $property );
    }

    #   Return undef if the requested parameter does not exist within 
    #   CGI object

    my $cgi = $self->query;
    return undef unless defined $cgi->param( $param );

    #   The determination of all information about the uploaded file is 
    #   performed by a private subroutine called _handle_file - This subroutine 
    #   returns a hash of all information determined about the uploaded file 
    #   which is be cached for subsequent requests.

    $self->{'_CACHE'}->{$param} = $self->_handle_file( $param ) unless exists $self->{'_CACHE'}->{$param};

    #   Return the requested property of the uploaded file

    return $self->{'_CACHE'}->{$param}->{$property};
}


sub DESTROY {}


sub _handle_file {
    my ( $self, $param ) = @_;
    my $cgi = $self->query;

    #   Determine and set the appropriate file system parsing routines for the 
    #   uploaded path name based upon the HTTP client header information.

    fileparse_set_fstype(
        sub {
            my $browser = HTTP::BrowserDetect->new;
            return 'MSWin32' if $browser->windows;
            return 'MacOS' if $browser->mac;
            $^O;
        }
    );
    my @file = fileparse( $cgi->param( $param ), '\.[^\.]*' );

    #   Return an undefined value if the file name cannot be parsed from the 
    #   file field form parameter.

    return undef unless $file[0];

    #   Determine whether binary mode is required in the handling of uploaded 
    #   files - This subroutine is based upon the $CGI::needs_binmode 
    #   subroutine in CGI.pm
    #
    #   Binary mode is deemed to be required for Windows, OS/2 and VMS 
    #   platforms.

    my $binmode = sub {
        my $OS;
        unless ( $OS = $^O ) {
            require Config;
            $OS = $Config::Config{'osname'};
        }
        return ( ( $OS =~ /(OS2)|(VMS)|(Win)/i ) ? 1 : 0 );
    };

    #   Pass uploaded file into temporary file handle - This is somewhat 
    #   redundant given the temporary file generation within CGI.pm, however is 
    #   included to reduce dependence upon the CGI.pm module.  

    my $buffer;
    my $fh = IO::File->new_tmpfile;
    binmode( $fh ) if $binmode;
    while ( read( $cgi->param( $param ), $buffer, 1024 ) ) {
        $fh->write( $buffer, length( $buffer ) );
    }

    #   Hold temporary file open, move file pointer to start - As the temporary 
    #   file handle returned by the IO::File::new_tmpfile method is only 
    #   accessible via this handle, the file handle must be held open for all 
    #   operations.

    $fh->seek( 0, 0 );

    #   Retrieve the MIME magic file, if this has been defined, and construct 
    #   the File::MMagic object for the identification of the MIME type of the 
    #   uploaded file.

    my $mime_magic = $self->mime_magic;
    my $magic = length $mime_magic ? File::MMagic->new( $mime_magic ) : File::MMagic->new;

    my $properties = {
        'file_handle'   =>  $fh,
        'file_name'     =>  $file[0] . $file[2],
        'file_type'     =>  lc substr( $file[2], 1 ),
        'mime_type'     =>  $magic->checktype_filehandle($fh)
    };

    #   Hold temporary file open, move file pointer to start - As the temporary 
    #   file handle returned by the IO::File::new_tmpfile method is only 
    #   accessible via this handle, the file handle must be held open for all 
    #   operations.
    #
    #   The importance of this operation here is due to the MIME type 
    #   identification routine of File::MMagic on the open file handle 
    #   (File::MMagic->checktype_filehandle), which may or may not reset the 
    #   file pointer following its operation.

    $fh->seek( 0, 0 );
    
    return $properties;
}


sub mime_magic {
    my ( $self, $magic ) = @_;

    #   If a filename is passed to this subroutine as an argument, this filename 
    #   is taken to be the file containing file MIME types and magic numbers 
    #   which File::MMagic uses for determining file MIME types.
    
    $self->{'_MIME'} = $magic if defined $magic;
    return $self->{'_MIME'};
}


sub new {
    my ( $class ) = @_;

    my $self = bless {
        '_CACHE'    =>  {},
        '_CGI'      =>  CGI->new,
        '_MIME'     =>  ''
    }, $class;
    return $self;
}


sub query {
    my ( $self ) = @_;
    return $self->{'_CGI'};
}


1;


__END__

=pod

=head1 NAME

CGI::Upload - CGI class for handling browser file uploads

=head1 SYNOPSIS

 use CGI::Upload;

 my $upload = CGI::Upload->new;

 my $file_name = $upload->file_name('field');
 my $file_type = $upload->file_type('field');

 $upload->mime_magic('/path/to/mime.types');
 my $mime_type = $upload->mime_type('field');

 my $file_handle = $upload->file_handle('field');

=head1 DESCRIPTION

This module has been written to provide a simple and secure manner by which to 
handle files uploaded in multipart/form-data requests through a web browser.  
The primary advantage which this module offers over existing modules is the 
single interface which it provides for the most often required information 
regarding files uploaded in this manner.

This module builds upon primarily the B<CGI> and B<File::MMagic> modules and 
offers some tidy and succinct methods for the handling of files uploaded via 
multipart/form-data requests.

=head1 METHODS

The following methods are available through this module for use in CGI scripts 
and can be exported into the calling namespace upon request.

=over 4

=item B<new>

This object constructor method creates and returns a new B<CGI::Upload> object.  
In previously versions of B<CGI::Upload>, a mandatory argument of the B<CGI> 
object to be used was required.  This is no longer necessary due to the 
singleton nature of B<CGI> objects.

=item B<query>

Returns the B<CGI> object used within the B<CGI::Upload> class.  

=item B<file_handle('field')>

This method returns the file handle to the temporary file containing the file 
uploaded through the form input field named 'field'.  This temporary file is 
generated using the B<new_tmpfile> method of B<IO::File> and is anonymous in 
nature, where possible.

=item B<file_name('field')>

This method returns the file name of the file uploaded through the form input 
field named 'field' - This file name does not reflect the local temporary 
filename of the uploaded file, but that for the file supplied by the client web 
browser.

=item B<file_type('field')>

This method returns the file type of the file uploaded as specified by the 
filename extension - Please note that this does not necessarily reflect the 
nature of the file uploaded, but allows CGI scripts to perform cursory 
validation of the file type of the uploaded file.

=item B<mime_magic('/path/to/mime.types')>

This method sets and/or returns the external magic mime types file to be used 
for the identification of files via the B<mime_type> method.  By default, MIME 
identification is based upon internal mime types defined within the 
B<File::MMagic> module.

See L<File::MMagic> for further details.

=item B<mime_type('field')>

This method returns the MIME type of the file uploaded through the form input 
field named 'field' as determined by file magic numbers.  This is the best 
means by which to validate the nature of the uploaded file.

See L<File::MMagic> for further details.

=back

=head1 SEE ALSO

L<CGI>, L<File::MMagic>, L<HTTP::File>

=head1 COPYRIGHT

Copyright 2002, Rob Casey, rob@cowsnet.com.au

=head1 AUTHOR

Rob Casey, rob@cowsnet.com.au

=cut
