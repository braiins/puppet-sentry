# == Define: sentry::config
#
# Deploys a sentry config file. The configuration file will be stored
# in the home directory of the owner in .sentry/
#
# === Parameters
#
# Document parameters here.
#
# [*owner*]
#   owner of the configuration file
# [*filename*]
#   name of the configuration file within .sentry/ directory in user's home/ directory
# [*source*]
#   source for the file
# [*content*]
#   content of the file
#
# === Examples
#
#  sentry::config { 'sentry':
#   owner     => 'sentryadmin',
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
define sentry::config($owner, $filename, $source=undef, $content=undef) {
  include sentry::params
  
  $user_home = getparam(User[$owner], 'home')
  $config_path = "${user_home}/${sentry::config_dir}"

  file { "${config_path}/${filename}":
    content => $content,
    source  => $source,
    owner   => $owner,
    group   => $owner,
    mode    => '0640',
  }
}
