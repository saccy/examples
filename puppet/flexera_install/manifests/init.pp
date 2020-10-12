#Installs OS specific flexera agents
class flexera_install {

  case $::facts['os']['family'] {
    'windows': {
      include flexera_install::windows
    }
    'RedHat': {
      include flexera_install::rhel
    }
    'Debian': {
      include flexera_install::ubuntu
    }
    default: {
      fail("Module ${module_name} is not supported on ${::facts['os']['family']}")
    }
  }

}
