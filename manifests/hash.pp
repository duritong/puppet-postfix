/*
== Definition: postfix::hash

Creates postfix hashed "map" files. It will create "${name}", and then build
"${name}.db" using the "postmap" command. The map file can then be referred to
using postfix::config.

Parameters:
- *name*: the name of the map file.
- *ensure*: present/absent, defaults to present.
- *source*: file source.

Requires:
- Class["postfix"]

Example usage:

  node "toto.example.com" {

    include postfix

    postfix::hash { "/etc/postfix/virtual":
      ensure => present,
    }
    postfix::config { "virtual_alias_maps":
      value => "hash:/etc/postfix/virtual"
    }
  }

*/
define postfix::hash ($ensure="present", $source = false) {
  include ::postfix
  case $source {
    false: {
      file {"${name}":
        ensure  => $ensure,
        mode    => 600,
        owner   => root,
        group   => root,
        seltype => $postfix::postfix_seltype,
        require => Package["postfix"],
      }
    }
    default: {
      file {"${name}":
        ensure  => $ensure,
        mode    => 600,
        owner   => root,
        group   => root,
        source  => $source,
        seltype => $postfix::postfix_seltype,
        require => Package["postfix"],
      }
    }
  }

  file {"${name}.db":
    ensure  => $ensure,
    mode    => 600,
    require => [File["${name}"], Exec["generate ${name}.db"]],
    seltype => $postfix::postfix_seltype,
  }

  exec {"generate ${name}.db":
    command => "postmap ${name}",
    #creates => "${name}.db", # this prevents postmap from being run !
    subscribe => File["${name}"],
    refreshonly => true,
    require => Package["postfix"],
  }
}
