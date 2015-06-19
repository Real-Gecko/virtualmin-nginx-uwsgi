#!/usr/bin/perl

require 'virtualmin-nginx-uwsgi-lib.pl';
&ReadParse();

#use Data::Dumper;

&ui_print_unbuffered_header(undef, $module_info{'desc'}, "", undef, 1, 1);
$d = &virtual_server::get_domain_by("dom", $in{'dom'});

%conf = ();
$conf{'venv_python_version'} = $in{'venv_python_version'};
$conf{'venv_requirements'} = $in{'venv_requirements'};

&$virtual_server::first_print($text{'venv_setup'});
&setup_venv($d, \%conf);
&reload_services;
&$virtual_server::second_print($virtual_server::text{'setup_done'});
