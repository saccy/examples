#Installs flexera managesoft on RHEL
class flexera_install::rhel (
  $dirs,
  $files,
  $source,
  $service,
) {

  file { $dirs:
    ensure => 'directory',
  }

  $files.each |$key, $value| {
    file { $value['name']:
      path   => "${value['path']}/${value['name']}",
      source => "${source}/${value['name']}",
    }
  }

  package { split($files['package']['name'], '[-]')[0]:
    source   => "${files['package']['path']}/${files['package']['name']}",
    provider => 'rpm',
    notify   => Service[$service],
  }

  service { $service:
    ensure => 'running',
  }

}
