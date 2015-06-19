do 'virtualmin-nginx-uwsgi-lib.pl';

sub feature_name {
    return $text{'feature_name'};
}

sub feature_label {
    return $text{'feature_label'};
}

sub feature_check {
    if (! &has_command($config{'nginx_cmd'})) {
        return $text{'feature_requires_nginx'};
    }
    if (! &has_command($config{'uwsgi_cmd'})) {
        return $text{'feature_requires_uwsgi'};
    }
    if (! &has_command($config{'virtualenv_cmd'})) {
        return $text{'feature_requires_virutalenv'};
    }
    else {
        return undef;
    }
}

sub feature_losing {
    return $text{'feature_losing'};
}

sub feature_disname {
    return $text{'feature_disname'};
}

sub feature_clash {
    my ($d) = @_;
    if ($d->{'virtualmin-nginx'} or $d{'web'}) {
        return $text{'feature_clash'};
    }
    if (-r "$config{'nginx_sites_available'}/$d->{'dom'}.ini") {
        return $text{'feature_clash_nginx'};
    }
    if (-r "$config{'uwsgi_apps_available'}/$d->{'dom'}.ini") {
        return $text{'feature_clash_uwsgi'};
    } else {
        return undef;
    }
}

sub feature_depends {
    my ($d) = @_;
    return $text{'feature_depends_unix'} if (!$d->{'unix'} && !$d->{'parent'});
    return $text{'feature_depends_dir'} if (!$d->{'dir'} && !$d->{'alias'});
    return $text{'feature_depends_web'} if ($d->{'web'});
    return $text{'feature_depends_nginx'} if ($d->{'virtualmin-nginx'});
    return undef;
}

sub feature_suitable {
    my ($parentdom, $aliasdom, $subdom) = @_;
    return $aliasdom ? 0 : 1;
}

sub feature_setup {
    my ($d) = @_;

    %conf = ();
    $conf{'client_max_body_size'} = '16';

    &virtual_server::generate_default_certificate($d);
    
    &$virtual_server::first_print($text{'feature_setup'});
    &create_nginx_config($d, \%conf);

    &$virtual_server::second_print($virtual_server::text{'setup_done'});

    # Add nginx user to domain group
    my $web_user = $config{'nginx_user'};
    if ($web_user && $web_user ne 'none') {
        &virtual_server::add_user_to_domain_group($d, $web_user, 'setup_webuser');
    }
#    &reload_services;
    system("$config{'nginx_reload_cmd'} >/dev/null 2>&1");
}

sub feature_delete {
    my ($d) = @_;
    &$virtual_server::first_print($text{'feature_delete'});
    &unlink_file(
        "$config{'nginx_sites_available'}/$d->{'dom'}.conf",
        "$config{'uwsgi_apps_available'}/$d->{'dom'}.ini"
    );
    if($config{'nginx_sites_enabled'}) {
        &unlink_file(
            "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf",
        );
    }
    if($config{'uwsgi_apps_enabled'}) {
        &unlink_file(
            "$config{'uwsgi_apps_enabled'}/$d->{'dom'}.ini",
        );
    }
    &reload_services;
    system("killall uwsgi >/dev/null 2>&1");
    &$virtual_server::second_print($virtual_server::text{'setup_done'});
}

sub feature_links {
    local ($d) = @_;
    return ( { 'mod' => $module_name,
               'desc' => $text{'venv_manage'},
               'page' => 'edit_venv.cgi?dom='.$d->{'dom'},
               'cat' => 'services',
             },
             { 'mod' => $module_name,
               'desc' => $text{'feature_manage'},
               'page' => 'edit_domain.cgi?dom='.$d->{'dom'},
               'cat' => 'services',
             } );
}

sub feature_hlink
{
    return "index";
}
