#!/usr/bin/perl

require 'virtualmin-nginx-uwsgi-lib.pl';
&ReadParse();

&ui_print_header(undef, $module_info{'desc'}, "", undef, 1, 1);

if (!defined $in{'wsgi_module'} or $in{'wsgi_module'} eq '') {
    print $text{'error_module_name_empty'};
} else {
    $d = &virtual_server::get_domain_by("dom", $in{'dom'});
    %uwsgi_conf = ();
    %nginx_conf = ();
    $d->{'ssl'} = $in{'ssl'} ? 1 : 0;
    &virtual_server::save_domain($d);
    $uwsgi_conf{'wsgi_module'} = $in{'wsgi_module'};
    $nginx_conf{'static_paths'} = $in{'nginx_static_paths'};
    $nginx_conf{'client_max_body_size'} = $in{'nginx_max_body_size'};
    #$conf{'project_path'} = $in{'project_path'};

    &$virtual_server::first_print($text{'domain_setup'});

    &unlink_file(
        "$config{'nginx_sites_available'}/$d->{'dom'}.conf",
        "$config{'uwsgi_apps_available'}/$d->{'dom'}.ini",
    );
    if($config{'uwsgi_apps_enabled'}) {
        &unlink_file(
            "$config{'uwsgi_apps_enabled'}/$d->{'dom'}.ini",
        );
    }
    if($config{'nginx_sites_enabled'}) {
        &unlink_file(
            "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf",
        );
    }

    &create_nginx_config($d, \%nginx_conf);
    &create_uwsgi_ini($d, \%uwsgi_conf);
    &reload_services;
    system("$config{'uwsgi_restart'} $d->{'dom'}.ini >/dev/null 2>&1");
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}
