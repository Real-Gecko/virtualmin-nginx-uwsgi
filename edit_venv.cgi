#!/usr/bin/perl

require 'virtualmin-nginx-uwsgi-lib.pl';
&ReadParse();

@pythonv= (
        ['python2', 'Python version 2'],
        ['python3', 'Python version 3']
    );
$d = &virtual_server::get_domain_by("dom", $in{'dom'});

&ui_print_header(undef, $module_info{'desc'}, "", undef, 1, 1);
print &ui_post_header("$in{'dom'}");

use Data::Dumper;

%venv_conf = get_venv_config($d);

if (index($venv_conf{'python'}, 'Python 3') != -1) {
    $python = 'python3';
} else {
    $python = 'python2';
}
print &ui_form_start("save_venv.cgi", "post");
print &ui_hidden("dom", $in{'dom'}),"\n";
print &ui_table_start($text{'venv_setup_description'},  "style='width: 100%;'", 2);

print &ui_table_span($text{'venv_setup'});

print &ui_table_row($text{'venv_python_version'}, &ui_select("venv_python_version", $python, \@pythonv));
print &ui_table_row($text{'venv_requirements'}, &ui_textarea("venv_requirements", $venv_conf{'modules'}, 20, 80, undef, undef, "style='wdith: 100%;'"));

print &ui_table_end();
print &ui_form_end([ [ "save", $text{'save'} ] ]);

&ui_print_footer("/", $text{'index'});
