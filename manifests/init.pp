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
#
# === Examples
#
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
$http_port, $url_prefix, $allowed_hosts, $secret_key, $server_email) inherits sentry::params {

  $sentry_exec = '/usr/local/bin/sentry'
  $sentry_init = "${sentry_exec} init"
  $sentry_upgrade = "${sentry_exec} upgrade"

  $user_home = getparam(User[$user], 'home')
  $config_path = "${user_home}/${config_dir}"

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
	'before'   => Package['sentry'],
      }
    }
    create_resources("sentry::${backend_type}_db", $db_params)
  }

  file { $config_path:
    ensure => directory,
    owner  => $user,
    group  => $user,
  } ->
  package { 'sentry':
    ensure   => present,
    provider => pip,
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
    require => Package['sentry']
  }

  # Deploy the super user (optional)
  if $deploy_super_user {
    exec { "${sentry_exec} createsuperuser --noinput --username=${super_user} --email=${super_user_email}":
    }
  }
}
