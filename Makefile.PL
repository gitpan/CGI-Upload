use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'                  =>  'CGI::Upload',
    'PREREQ_PM'             =>  {
        'CGI'                   =>  0,
        'File::Basename'        =>  0,
        'File::MMagic'          =>  0,   #    File::MMagic binmode support added 0.15
        'HTTP::BrowserDetect'   =>  0
    },
    'VERSION_FROM'          =>  'Upload.pm'
);
