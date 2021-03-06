puppet-uwsgi
============

A puppet module for installing and managing uwsgi

## Description

This module installs and configures [uWSGI](http://uwsgi-docs.readthedocs.org)
in [Emperor mode](http://uwsgi-docs.readthedocs.org/en/latest/Emperor.html).

It can also create and manage uwsgi applications that run under the emperor,
which are best defined in hiera.

Just about every option is configurable, so it should work on most distributions
by putting together a hiera file.

## Classes

### uwsgi

The main entry point. Simply ``include uwsgi`` to accept all the default
parameters. The service file template will, by default, auto-configure itself for
redhat init.d or upstart depending on the service provider.

#### Parameters

* `package_name`
   The package name to install.
   Default: 'uwsgi'

* `package_ensure`
   Package state.
   Default: 'installed'

   If 'absent' or 'purged', then remove the `service_file` and `config_file`
   also

* `package_provider`
   The provider to use to install the package.
   Default: 'pip'

* `service_name`
   The name of the service to run uwsgi.
   Default: 'uwsgi'

* `service_file`
   The location of the service file.
   Default: '/etc/init/uwsgi.conf'

* `service_template`
   The location of the template to generate the *service_file*.
   Default: 'uwsgi/uwsgi_upstart.conf.erb'

* `service_ensure`
   The service state.
   Default: true

* `service_enable`
   The service onboot state.
   Default: true

* `service_provider`
   The service provider.
   Default: 'upstart'

   `upstart` is required for the default `service_file`, and
   works on RedHat 6. Setting `service_provider` to `redhat`
   will now deploy the init.d service file, unless you specifically
   set `service_template` etc.
   `systemd` will create a systemd service on RedHat 7 and Debian 8.

* `manage_service_file`
   Whether to override the system service file if it exists.
   Default: true

*  `binary_directory`
   Default: '/usr/sbin'

   Directory containing the uwsgi binary. Used by the `systemd`
   service_provider; not used by the `upstart` or `redhat` service_provider
   parameter.

* `config_file`
   The location of the uwsgi config file.
   Default: '/etc/uwsgi.ini'

* `log_dir`
   The location of the uwsgi emperor log.
   Default: '/var/log/uwsgi/uwsgi-emperor.log'

* `log_rotate`
   Whether or not to deploy a logrotate script.
   Accepts: 'yes', 'no', 'purge'
   Default: 'no'

* `app_directory`
   Vassal directory for application config files.

   RedHat default: '/etc/uwsgi.d'
   Other default: '/etc/uwsgi/apps-enabled'

* `install_pip`
   Install pip if it's not already installed?
   Default: true

* `install_python_dev`
   Install python header files if not already installed?
   Default: true

* `python_pip`
   Package to be installed for pip
   Default: 'python-pip'

* `python_dev`
   Package to be installed for python headers
   Default RedHat: 'python-devel'
   Default Other: 'python-dev'

* `emperor_options`
   Extra options to set in the emperor config file. Default: undef

#### Using Hiera

Sets up some custom options within the emperor config file:

```yaml
---
uwsgi::emperor_options:
  vacuum: 'True'
  reload-mercy: 8
```

Don't manage python or pip, and use apt-get to install uwsgi. Don't manage
the service file, as it will be provided by the package itself:

```yaml
---
uwsgi::install_pip: false
uwsgi::install_python_dev: false
uwsgi::package_provider: 'apt'
uwsgi::manage_service_file: false
```

Remove uwsgi:

```yaml
---
uwsgi::package_ensure: 'absent'
uwsgi::service_ensure: false
uwsgi::service_enable: false
uwsgi::install_pip: false
uwsgi::install_python_dev: false
```

## Defined Types

### uwsgi::app

Responsible for creating uwsgi applications that run under the uwsgi emperor.
You shouldn't need to use this type directly, as the `uwsgi` class will
automatically create all applications defined in hiera under the uwsgi::app
key. See the hiera section below for examples.

#### Parameters

* `ensure`
   Ensure the config file exists. Default: 'present'

* `template`
   The template used to construct the config file.
   Default: 'uwsgi/uwsgi_app.ini.erb'

* `uid`
   The user to run the application as. Required.
   May be the user name, not just the id.

* `gid`
   The group to run the application as. Required.
   May be the group name, not just the id.

* `application_options`
   Extra options to set in the application config file

* `environment_variables`
   Extra environment variabls to set in the application config file

#### Using Hiera

Configure a django application:

```yaml
---
uwsgi::app:
  django:
    ensure: 'present'
    uid: 'django'
    gid: 'django'
    application_options:
      chdir: '/path/to/project'
      module: 'mysite.wsgi:application'
      socket: '/tmp/uwsgi_django.sock'
      master: 'True'
      vaccum: 'True'
      max-requests: '5000'
      buffer-size: '32768'
      processes: 4
      threads: 8
```

Configure multiple applications (all yaml files are aggregated using
`hiera_hash`):

```yaml
# common.yaml
---
uwsgi::app:
  django_1:
    ensure: 'present'
    uid: 'django'
    gid: 'django'
    application_options:
      chdir: '/path/to/project'
      module: 'mysite.wsgi:application'
      socket: '/tmp/uwsgi_django.sock'


# role_app_server.yaml
---
uwsgi::app:
  django_2:
    ensure: 'present'
    uid: 'django'
    gid: 'django'
    application_options:
      chdir: '/path/to/project2'
      module: 'mysite.wsgi:application'
      socket: '/tmp/uwsgi_django2.sock'
```

Example using hiera to use Debian Jessie APT packages & default file locations

```yaml
---
classes:
  - uwsgi
uwsgi::package_name:
  - 'uwsgi-emperor'
  - 'uwsgi-plugins-all'
uwsgi::package_provider: 'apt'
uwsgi::service_name: 'uwsgi-emperor'
uwsgi::service_provider: 'debian'
uwsgi::manage_service_file: false
uwsgi::config_file: '/etc/uwsgi-emperor/emperor.ini'
uwsgi::log_dir: '/var/log/uwsgi/emperor.log'
uwsgi::app_directory: '/etc/uwsgi-emperor/vassals'
uwsgi::install_pip: false
uwsgi::install_python_dev: false
uwsgi::socket: undef
uwsgi::pidfile: '/run/uwsgi-emperor.pid'
uwsgi::emperor_options:
  uid: 'www-data'
  gid: 'www-data'
  workers: '2'
  no-orphans: 'true'
```

## Contributers

Contributions will be gratefully accepted.  Please go to the project page,
fork the project, make your changes locally and then raise a pull request.
Details on how to do this are available at
https://guides.github.com/activities/contributing-to-open-source.

### Additional Contributers

**Release**  | **PR/Issue/commit**                                                                                               | **Contributer**
-------------|-------------------------------------------------------------------------------------------------------------------|----------------------------------------
1.3.1        | [Add systemd support for Debian 8](https://github.com/rvdh/puppet-uwsgi/pull/16)                                  | [@rvdh](https://github.com/rvdh)
1.3.0        | [Add systemd support](https://github.com/rvdh/puppet-uwsgi/pull/14)                                               | [@andy-s-clark](https://github.com/andy-s-clark)
1.3.0        | [Make tyrant mode configurable](https://github.com/rvdh/puppet-uwsgi/pull/12)                                     | [@TravellingGuy](https://github.com/TravellingGuy)
1.3.0        | [Additional Options](https://github.com/rvdh/puppet-uwsgi/pull/11)                                                | [@elmerfud](https://github.com/elmerfud)
1.2.0        | [Support repeated application options by passing an array of values](https://github.com/rvdh/puppet-uwsgi/pull/6) | [@rayl](https://github.com/rayl)
1.1.0        | [Fix typo in Upstart script](https://github.com/rvdh/puppet-uwsgi/pull/5)                                         | [@Kodapa](https://github.com/Kodapa)
1.1.0        | [Support multiple env options](https://github.com/rvdh/puppet-uwsgi/pull/4)                                       | [@kimor79](https://github.com/kimor79)
1.0.1        | [Fix logging when using init.d](https://github.com/rvdh/puppet-uwsgi/pull/3)                                      | [@kimor79](https://github.com/kimor79)
1.0.0        | [init.d support](https://github.com/rvdh/puppet-uwsgi/pull/2)                                                     | [@kimor79](https://github.com/kimor79)
0.9.0        |                                                                                                                   | [@jarshwah](https://github.com/jarshwah)
