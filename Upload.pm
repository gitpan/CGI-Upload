package CGI::Upload;

use Carp;
use File::Basename;
use File::MMagic;
use HTTP::BrowserDetect;
use IO::File;

use strict;
use vars qw/ $VERSION @ISA @EXPORT @EXPORT_OK /;

@EXPORT_OK = qw/ file_handle file_name file_type mime_magic mime_type /;

$VERSION = '1.01';


sub _handle_file {
    my $self = shift;
    my ($cgi, $param) = @_;

    my $mime_magic = $self->mime_magic;
    my $magic = 
        ( length $mime_magic ) ? 
        File::MMagic->new( $mime_magic ) :
        File::MMagic->new;

    fileparse_set_fstype(
        do {
            my $browser = HTTP::BrowserDetect->new;
            return 'MSWin32' if $browser->windows;
            return 'MacOS' if $browser->mac;
            $^O;
        }
    );
    my @file = fileparse($cgi->param($param), '\.[^\.]*');

    return undef unless $file[0];

    my $buffer;
    my $fh = IO::File->new_tmpfile;
    $fh->binmode if $CGI::needs_binmode;
    while (read($cgi->param($param), $buffer, 1024)) {
        $fh->write($buffer, length($buffer));
    }
    $fh->seek(0, 0);
    $fh->binmode if $CGI::needs_binmode;

    my $object = {
        'file_handle'   =>  $fh,
        'file_name'     =>  $file[0] . $file[2],
        'file_type'     =>  substr(lc $file[2], 1),
        'mime_type'     =>  $magic->checktype_filehandle($fh)
    };
    $fh->seek(0, 0);
    $fh->binmode if $CGI::needs_binmode;

    return $object;
}


sub file_handle {
    my $self = shift;
    my ($param) = @_;
    my $cgi = $self->{'_CGI'};

    return undef unless defined $cgi->param($param);

    $self->{'_PARAMS'}->{$param} = $self->_handle_file( $cgi, $param)
        unless exists $self->{'_PARAMS'}->{$param};

    return $self->{'_PARAMS'}->{$param}->{'file_handle'};
}


sub file_name {
    my $self = shift;
    my ($param) = @_;
    my $cgi = $self->{'_CGI'};

    return undef unless defined $cgi->param($param);

    $self->{'_PARAMS'}->{$param} = $self->_handle_file( $cgi, $param)
        unless exists $self->{'_PARAMS'}->{$param};

    return $self->{'_PARAMS'}->{$param}->{'file_name'};
}


sub file_type {
    my $self = shift;
    my ($param) = @_;
    my $cgi = $self->{'_CGI'};

    return undef unless defined $cgi->param($param);

    $self->{'_PARAMS'}->{$param} = $self->_handle_file( $cgi, $param)
        unless exists $self->{'_PARAMS'}->{$param};

    return $self->{'_PARAMS'}->{$param}->{'file_type'};
}


sub mime_magic {
    my $self = shift;
    my ($magic) = @_;
    if (defined $magic) {
        $self->{'_MMAGIC'} = $magic if -e $magic;
    }
    return $self->{'_MMAGIC'};
}


sub mime_type {
    my $self = shift;
    my ($param) = @_;
    my $cgi = $self->{'_CGI'};

    return undef unless defined $cgi->param($param);

    $self->{'_PARAMS'}->{$param} = $self->_handle_file( $cgi, $param)
        unless exists $self->{'_PARAMS'}->{$param};

    return $self->{'_PARAMS'}->{$param}->{'mime_type'};
}


sub new {
    my $class = shift;
    $class = ref $class if ref $class;

    my ($cgi) = @_;
    unless (( defined $cgi ) && ( $cgi->isa('CGI') )) {
        croak( "CGI::Upload->new : Single argument to method should be CGI.pm object" );
    }
    my $self = bless {
        '_CGI'      =>  $cgi,
        '_MMAGIC'   =>  '',
        '_PARAMS'   =>  {}
    }, $class;
    return $self;
}


1;


__END__

=head1 NAME

CGI::Upload - CGI class for handling browser file uploads

=head1 SYNOPSIS

  use CGI;
  use CGI::Upload;

  my $cgi = CGI->new;
  my $upload = CGI::Upload->new( $cgi );

  my $file_name = $upload->file_name( 'field_name' );
  my $file_type = $upload->file_type( 'field_name' );

  $upload->mime_magic( '/path/to/mime.types' );
  my $mime_type = $upload->mime_type( 'field_name' );

  my $file_handle = $upload->file_handle( 'field_name' );

=head1 DESCRIPTION

This module has been written to provide a simple and secure manner
by which to handle files uploaded in multipart/form-data requests
through a web browser.  The primary advantage which this module
offers over existing modules is the single interface providing the
most often required information regarding files uploaded through
multipart/form-data requests.

Building on L<CGI> and L<File::MMagic>, this module offers a very
tidy and succinct interface for handling of file uploads.

=head1 METHODS

The following methods are available through this module for use in
CGI scripts and can be exported upon request.

=over 4

=item B<new( $cgi )>

This method creates and returns a new CGI::Upload object, the only
mandatory argument to which is a CGI.pm object.  This is in part
because only a single CGI.pm object can be initiated within a given
CGI script.

=item B<file_handle( 'field_name' )>

This method returns the file handle to a temporary file containing
the file uploaded through the form input field named 'field_name'.

=item B<file_name( 'field_name' )>

This method returns the file name of the file uploaded through the
form input field named 'field_name' - This file name does not 
reflect the local temporary file name of the uploaded file, but
that supplied by the client web browser.

=item B<file_type( 'field_name' )>

This method returns the file type of the file uploaded as indicated
by the file extension - This does not necessarily reflect the
nature of the file uploaded, but allows CGI scripts to perform 
cursory validation on the file uploaded.

=item B<mime_magic( '/path/to/mime.types' )>

This method sets and/or returns the external magic mime types file
to be used for identification of files via the mime_type method.  By
default, identification is based upon internal mime types defined
within the File::MMagic module.

See L<File::MMagic> for further details.

=item B<mime_type( 'field_name' )>

This method returns the file type of the file uploaded through the
form input field named 'field_name' as indicated by the file magic
numbers.  This is the best means by which to validate the nature
of the uploaded file.

See L<File::MMagic> for further details.

=back

=head1 SEE ALSO

L<CGI>, L<File::MMagic>, L<HTTP::File>

=head1 COPYRIGHT

Copyright 2002, Rob Casey, rob@cowsnet.com.au

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Rob Casey, rob@cowsnet.com.au

=cut

