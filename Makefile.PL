use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'                  =>  'CGI::Upload',
    'PREREQ_PM'             =>  {
        'File::MMagic'          =>  1.16,
        'HTTP::BrowserDetect'   =>  0.97
    },
    'VERSION_FROM'          =>  'lib/CGI/Upload.pm'
);
