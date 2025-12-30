# == Class awscli2::uninstall
#
# This class is called from awscli2 to un-install the CLI.
#
class awscli2::uninstall {
  # Do not filebucket 2k+ files
  File {
    backup => false,
  }

  # XXX - hinge this on the `installed` fact, or just blindly remove?
  if $facts['umd_awscli2_version'] {
    file { "${awscli2::install_dir}/v2":
      ensure  => absent,
      force   => true,
      purge   => true,
      recurse => true,
    }

    $bin_files = [
      "${awscli2::bin_dir}/aws",
      "${awscli2::bin_dir}/aws_completer",
    ]
    file { $bin_files:
      ensure => absent,
    }
  }
}
