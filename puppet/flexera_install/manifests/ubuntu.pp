#Installs flexera managesoft on Ubuntu
class flexera_install::ubuntu (
  $dirs,
  $files,
  $source,
  $service,
) {

  file { $dirs:
    ensure => 'directory',
  }

  $files.each |$key, $value| {
    file { "${value['path']}/${value['name']}":
      source => "${source}/${value['name']}",
    }
  }

  package { split($files['package']['name'], '[_]')[0]:
    source   => "${files['package']['path']}/${files['package']['name']}",
    provider => 'dpkg',
    notify   => Service[$service],
  }

  service { $service:
    ensure => 'running',
  }

}
