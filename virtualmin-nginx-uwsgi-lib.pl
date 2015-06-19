use WebminCore;
&init_config();
&foreign_require("virtual-server", "virtual-server-lib.pl");

sub get_uwsgi_config {
    my ($d) = @_;
    my $lines = &read_file_lines("$config{'uwsgi_apps_available'}/$d->{'dom'}.ini");
    my %conf = ();
    foreach my $line (@$lines) {
        my ($n, $v) = split(/\s+=\s+/, $line, 2);
        if ($n) {
           $conf{$n} = $v;
        }
    }
    return %conf;
}

sub get_venv_config {
    my ($d) = @_;
    my %conf = ();
    $conf{'python'} = &backquote_command("$d->{'home'}/venv/bin/python --version");
    $conf{'modules'} = &backquote_command("$d->{'home'}/venv/bin/pip freeze");
    return %conf;
}

sub get_nginx_config {
    my ($d) = @_;
    my $lines = &read_file_lines("$config{'nginx_sites_available'}/$d->{'dom'}.conf");
    return $lines;
}

sub create_nginx_config {
    my $d = shift;
    my $conf = shift;

    open(FILE, ">> $config{'nginx_sites_available'}/$d->{'dom'}.conf") or die ("Unable to create nginx config");

if ($d->{'ssl'}) {
print FILE <<"NGINX";
server {
    server_name $d->{'dom'} www.$d->{'dom'};
    listen $d->{'ip'};
    rewrite ^ https://\$server_name\$request_uri? permanent;
}

server {
    server_name $d->{'dom'} www.$d->{'dom'};
    listen $d->{'ip'}:443 ssl;
    ssl_certificate $d->{'ssl_cert'};
    ssl_certificate_key $d->{'ssl_key'};
    ssl_protocols TLSv1.1 TLSv1.2;

NGINX
} else {
print FILE <<"NGINX";
server {
    server_name $d->{'dom'} www.$d->{'dom'};
    listen $d->{'ip'};

NGINX
}

print FILE <<"NGINX";
    root $d->{'home'}/public_html;

    client_max_body_size $conf->{'client_max_body_size'}M;

    location / {
        uwsgi_pass  unix:///var/run/uwsgi/app/$d->{'dom'}/socket;
        include     uwsgi_params;
    }
NGINX

    @static_paths = split(' ', $conf->{'static_paths'});

    foreach $static_path(@static_paths) {
        print FILE "\n    location /$static_path {\n";
        print FILE "        root $d->{'home'}/public_html;\n";
        print FILE "    }\n";
    }

print FILE <<"NGINX";
}
NGINX

    close(FILE);
    if($config{'nginx_sites_enabled'}) {
        &symlink_file("$config{'nginx_sites_available'}/$d->{'dom'}.conf", "$config{'nginx_sites_enabled'}/$d->{'dom'}.conf");
    }
}

sub create_uwsgi_ini {
    my $d = shift;
    my $conf = shift;
    
    if (!-r "$d->{'home'}/.tmp") {
        &make_dir("$d->{'home'}/.tmp", oct(755), 0);
        &set_ownership_permissions($d->{'user'}, $d->{'group'}, undef, "$d->{'home'}/.tmp");
    }
    open(FILE, ">> $config{'uwsgi_apps_available'}/$d->{'dom'}.ini") or die ("Unable to create uwsgi ini for domain");
print FILE <<"uWSGI";
[uwsgi]
chdir = $d->{'home'}/public_html
home = $d->{'home'}/venv
pidfile = /tmp/uwsgi-$d->{'dom'}.pid
uid = $d->{'user'}
gid = $d->{'group'}
module = $conf->{'wsgi_module'}
master = True
vacuum = True
chmod-socket=660
chown-socket = $config{'nginx_user'}:$config{'nginx_user'}
uWSGI
    close(FILE);
    if($config{'uwsgi_apps_enabled'}) {
        &symlink_file("$config{'uwsgi_apps_available'}/$d->{'dom'}.ini", "$config{'uwsgi_apps_enabled'}/$d->{'dom'}.ini");
    }
}

sub setup_venv {
    my $d = shift;
    my $conf = shift;
    &unlink_file("$d->{'home'}/venv");

    print "<pre>";
    print &backquote_command("virtualenv -p $conf->{'venv_python_version'} $d->{'home'}/venv");
    print "</pre>";

    &$virtual_server::second_print($text{'venv_requirements_install'});
    @reqs = split(' ', $conf{'venv_requirements'});

    foreach $req(@reqs) {
        print "<pre>";
        print &backquote_command("$d->{'home'}/venv/bin/pip install $req");    
        print "</pre>";
    }
    system("chown $d->{'user'}:$d->{'group'} $d->{'home'}/venv -R");
}

sub reload_services {
    system("$config{'nginx_restart'} >/dev/null 2>&1");
#    system("$config{'uwsgi_restart'} >/dev/null 2>&1");
}

1;

