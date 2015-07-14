# == Define: sentry::postgres_backend
#
# Deploys a postgres backend configuration for a particular system user.
#
# === Parameters
#
# [*name*]
#   Name of the system user that will have the backend installed
# [*db_host*]
#   Host that runs the the database instance
# [*db_host*]
#   Host that runs the the database instance
# [*db_user*]
#   User of the database
# [*db_password*]
#   Password for the database user
#
#
# === Examples
#
#  sentry::postgres_backend { 'admin':
#   db_host     => 'localhost',
#   db_port     => '5432',
#   db_name     => 'sentry',
#   db_user     => 'sentry_admin',
#   db_password => 'sentryadmin_passwd',
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
define sentry::postgres_backend($db_host, $db_port, $db_name, $db_user,
$db_password) {

  $django_backend = 'django.db.backends.postgresql_psycopg2'
  sentry::config { "${name}-sentry::postgres_backend":
    owner    => $name,
    filename => 'sentry_backend_config.py',
    content  => template('sentry/sentry_backend_config.py.erb'),
  }
}
