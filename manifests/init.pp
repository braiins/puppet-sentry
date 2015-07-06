# == Class: sentry
#
# Full description of class sentry here.
#
# === Parameters
#
# Document parameters here.
#
# [*user*]
#   System user name that runs sentry
# [*db_host*]
#   Optional database host where the backend runs. A new database will
#   be deployed when undefined or points to localhost
# [*db_name*]
#   Name of the sentry database
# [*db_password*]
#   Password for the sentry database user
# [*backend_type*]
#   See sentry::${backend_type}_{db,backend} defines
# [*super_user*]
#   Name of the super user/admin of sentry. User resource must exist!
# [*super_user_email*]
#   Email of the super user
# [*http_port*]
#   Port where the web server will listen on
# [*url_prefix*]
#   URL for accessing the web interface
# [*allowed_hosts*]
#   list of aliases (by name) from which it is allowed to access the sentry server API
# [*secret_key*]
#   Django secret key for the sentry application
# [*server_email*]
#   From: field for email sent by the server
# [*enable_supervisord_conf*]
#   Enables the sentry service in supervisor (requires supervisor
#   class to be instantiated)
#
# === Examples
#
# # The following snippet deploys admin user, supervisor and sentry
# # with supervisor management enabled on a Debian system.
#
# $executable_path = '/usr/bin'
# $config_path = '/etc/supervisor'
# user { 'admin':
#  ensure     => present,
#  home       => '/home/admin',
#  managehome => true,
# } ->
# class { '::supervisord':
#   package_provider => 'aptitude',
#   executable_path  => $executable_path,
#   executable       => "${executable_path}/supervisord",
#   executable_ctl   => "${executable_path}/supervisorctl",
#   service_name     => 'supervisor',
#   install_init     => false,
#   config_include   => '/etc/supervisor/conf.d',
#   config_file      => '/etc/supervisor/supervisord.conf',
# } ->
# class { 'sentry':
#   user                    => 'admin',
#   enable_supervisord_conf => true,
# }
#
# === Authors
#
# Braiins Systems s.r.o. <info@braiins.cz>
#
# === Copyright
#
# Copyright 2014 Braiins Systems s.r.o.
#
class sentry($user, $db_host='localhost', $db_port, $db_name='sentry', $db_user='sentry_admin',
$db_password, $backend_type, $super_user='admin', $super_user_email,
$http_port, $url_prefix, $allowed_hosts, $secret_key, $server_email,
$enable_supervisord_conf=false) inherits sentry::params {


  $user_home = getparam(User[$user], 'home')
  $sentry_root = "${user_home}/sentry"
  $sentry_venv_path = "${sentry_root}/.env"
  $config_path = "${user_home}/${config_dir}"

  $sentry_exec = "${sentry_venv_path}/bin/sentry"
  $sentry_init = "${sentry_exec} init"
  $sentry_upgrade = "${sentry_exec} upgrade"

  # All exec's run under the admin user
  Exec {
    user => $user,
  }

  # Deploy complete database when local db_host has
  # been specified
  if ($db_host == 'localhost') or ($db_host == $::ipaddress_lo)
  or ($db_host == undef) {
    $db_params = {
      $db_name => {
	'user'     => $db_user,
	'password' => $db_password,
	'before'   => Python::Pip['sentry'],
      }
    }
    create_resources("sentry::${backend_type}_db", $db_params)
  }

  file { $sentry_root:
     ensure => directory,
     owner  => $user,
     group  => $user,
  } ->
  package { ['libxslt1-dev',
             'libxml2-dev',
             'libffi-dev',
             'libpq-dev']:
    ensure => present,
  } ->
  class { 'redis':
    system_sysctl    => true,
    conf_nosave      => true,
  } ->
  python::virtualenv { $sentry_venv_path:
    ensure       => present,
    version      => 'system',
    systempkgs   => false,
    owner        => $user,
    group        => $user,
    cwd          => $sentry_root,
    timeout      => 0,
  } ->
  python::pip { ['sentry',
                 'psycopg2'
                ]:
    virtualenv => $sentry_venv_path,
  } ->
  file { $config_path:
     ensure => directory,
     owner  => $user,
     group  => $user,
  }

  # Deploy backend specific configuration
  $backend_params = {
    $user => {
      'db_host'     => $db_host,
      'db_port'     => $db_port,
      'db_name'     => $db_name,
      'db_user'     => $db_user,
      'db_password' => $db_password,
      'require'     => File[$config_path],
      'before'      => Sentry::Config["${user}-sentry"],
    }
  }
  create_resources("sentry::${backend_type}_backend", $backend_params)

  # Generic part of the configuration
  sentry::config { "${user}-sentry":
    owner    => $user,
    filename => 'sentry.conf.py',
    content  => template('sentry/sentry.conf.py.erb')
  } ->
  # Populate/upgrade the database tables
  exec { $sentry_upgrade:
    require => [ Python::Pip['sentry'],
                 Python::Pip['psycopg2']
               ],
  }

  # Deploy the super user (optional)
  if $deploy_super_user {
    exec { "${sentry_exec} createsuperuser --noinput --username=${super_user} --email=${super_user_email}":
    }
  }

  if $enable_supervisord_conf {
    Supervisord::Program {
      autostart       => true,
      # NOTE: autorestart is not bool but string as it may have values:
      # true/false/unexpected
      autorestart     => 'true',
      redirect_stderr => true,
      user            => $user,
      environment => {
        'HOME'   => $user_home,
        'USER'   => $user
      },
      stdout_logfile_maxbytes => '50MB',
      stdout_logfile_backups  => '7',
      stderr_logfile_maxbytes => '50MB',
      stderr_logfile_backups  => '7',
    }

    supervisord::group { 'sentry':
      priority => '100',
      programs => ['sentry-web', 'sentry-worker',]
    } ->
    supervisord::program { 'sentry-web':
      command => "${sentry_exec} start",
    } ->
    supervisord::program { 'sentry-worker':
      command => "${sentry_exec} celery worker -B",
    }
  }
}
