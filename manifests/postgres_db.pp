# == Class: sentry::postgres_db
#
# Deploys a postgres database
#
# === Parameters
#
# Document parameters here.
#
# [*name*]
#   Name of the define is used as the name for the database
# [*user*]
#   Database user
# [*password*]
#   Password for the database user
#
#
# === Examples
#
#  sentry::postgres_db { 'sentry':
#   user     => 'sentryadmin',
#   password => 'sentryadmin_passwd',
#  }
#
# === Authors
#
# Braiins Systems s.r.o. <info@braiins.cz>
#
# === Copyright
#
# Copyright 2014 Braiins Systems s.r.o.
#
define sentry::postgres_db($user, $password) {

  postgresql::server::role { $user:
    password_hash => postgresql_password($user, $password),
  } ->
  postgresql::server::database { $name:
    owner    => $user,
    encoding => 'UTF-8',
  }
}
