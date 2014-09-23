# sentry

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with sentry](#setup)
	* [What sentry affects](#what-sentry-affects)
	* [Setup requirements](#setup-requirements)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

This module configures sentry exceptions tracker and analyzer. It has
been tested with puppet 3.7.x on Debian systems.

## Module Description

Sentry is a robust exceptions tracker and analyzer. This module sets
up the sentry instance and a database backend including deployment of
the required database scheme and admin user.


## Setup

### What sentry affects

* the module deploys a new database with admin user (called 'sentry')
  only if the specified database host points to localhost. Using a
  non-local backend assumes presence of an empty database.

### Setup Requirements **OPTIONAL**

Nothing special.


## Usage

It is recommended/preferable to configure the site specific parameters
of the main class via hiera:

	sentry::db_port: '5432'
	sentry::db_password: 'some-password'
	sentry::backend_type: 'postgres'
	sentry::deploy_super_user: false
	sentry::super_user: 'admin'
	sentry::super_user_email: 'admin@youradminemail.com'
	sentry::http_port: '80'
	sentry::url_prefix: 'yoursentrysite.com'
	sentry::allowed_hosts:
	  - 'yoursentrysite.com'
	sentry::secret_key: 'djangosecretkey''
	sentry::server_email: 'sentry@yoursitedomain.com'

The sentry class is then instantiated as follows:

	class { 'sentry':
	  user => 'sentryadmin',
	}


## Reference

Classes:
* [sentry::params](#class-sentryparams)

Resources:

* [sentry::postgres_db](#resource-sentrypostgres_db)
* [sentry::postgres_backend](#resource-sentrypostgres_backend)
* [sentry::config](#resource-sentryconfig)

## Limitations

The module currently supports only postgres backend and has been
tested on Debian Wheezy and puppet 3.7.1.

## Development

Patches and improvements are welcome as pull requests for the central
project github repository.

## Contributors
