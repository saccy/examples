#Installs flexera FlexNet Inventory Agent on windows
class flexera_install::windows (
  $dir,
  $files,
  $source,
  $services,
) {

  file { $dir:
    ensure => 'directory',
  }

  $files.each |$key, $value| {
    file { $value['name']:
      path    => "${value['path']}/${value['name']}",
      source  => "${source}/${value['name']}",
      notify  => Exec["C:\\Windows\\System32\\reg.exe import ${files['registry']['path']}\\${files['registry']['name']}"],
      require => File[$dir],
    }
  }

  exec { "C:\\Windows\\System32\\reg.exe import ${files['registry']['path']}\\${files['registry']['name']}":
    cwd         => $dir,
    refreshonly => true,
    before      => Package['FlexNet Inventory Agent'],
  }

  package { 'FlexNet Inventory Agent':
    source          => "${files['package']['path']}\\${files['package']['name']}",
    install_options => [
      '/quiet'
    ],
  }

  service { $services:
    ensure => 'running',
  }

}
