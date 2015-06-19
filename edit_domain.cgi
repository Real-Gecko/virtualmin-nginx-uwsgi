#!/usr/bin/perl

require 'virtualmin-nginx-uwsgi-lib.pl';
&ReadParse();

$d = &virtual_server::get_domain_by("dom", $in{'dom'});
%uwsgi_conf = get_uwsgi_config($d);

&ui_print_header(undef, $module_info{'desc'}, "", undef, 1, 1);
print &ui_post_header("$in{'dom'}");

# Get current Nginx config for domain if exists
my $lines = get_nginx_config($d);
my $static_paths;
my $nginx_max_body_size;

foreach $line(@$lines) {
    if ($line =~ m/location \/([a-z0-9-]+) {/) {
        $static_paths.=$1.chr(13);
    }
    if ($line =~ m/client_max_body_size ([0-9-]+)M/) {
        $nginx_max_body_size = $1;
    }
}

print &ui_form_start("save_domain.cgi", "post");
print &ui_hidden("dom", $in{'dom'}),"\n";
print &ui_table_start($text{'domain_setup_description'},  "style='width: 100%;'", 2);
print &ui_table_row($text{'nginx_ssl'}, &ui_checkbox("ssl", "ssl", undef, $d->{'ssl'}));
print &ui_table_row($text{'nginx_static_paths'}, &ui_textarea("nginx_static_paths", $static_paths, 5, 80, undef, undef, "style='wdith: 100%;'"));
print &ui_table_row($text{'nginx_max_body_size'}, &ui_textbox("nginx_max_body_size", $nginx_max_body_size, 50));

print &ui_table_span($text{'venv_setup'});

print &ui_table_row($text{'wsgi_module'}, &ui_textbox("wsgi_module", $uwsgi_conf{'module'}, 50));

print &ui_table_end();
print &ui_form_end([ [ "save", $text{'save'} ] ]);

&ui_print_footer("/", $text{'index'});
