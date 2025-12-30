# == Class awscli2::install
#
# This class is called from awscli2 to install the CLI.
#
class awscli2::install {
  # Do not filebucket 2k+ files
  File {
    backup => false,
  }

  # deliver a custom fact which returns the version of the AWS CLI
  # we have installed
  if !defined(File['/etc/puppetlabs/facter']) {
    file { '/etc/puppetlabs/facter':
      ensure => 'directory',
    }
  }
  if !defined(File['/etc/puppetlabs/facter/facts.d']) {
    file { '/etc/puppetlabs/facter/facts.d':
      ensure => 'directory',
    }
  }
  file { '/etc/puppetlabs/facter/facts.d/awscli2.sh':
    ensure  => file,
    content => epp('awscli2/facts.d/awscli2.sh', {
        'bin_dir' => $awscli2::bin_dir,
    }),
    mode    => '0555',
  }

  # Figure out if we need to do a new install (nothing installed),
  # an upgrade (existing install version differs to requested version)
  # or nothing (existing install version matches requested version)
  if $facts['umd_awscli2_version'] {
    if $facts['umd_awscli2_version'] == $awscli2::version {
      # Nothing to do, installed matches requested.
    } else {
      # Installed differs from requested, need to do an upgrade install.
      $need_upgrade = true
    }
  } else {
    # nothing currently installed.
    $need_install = true
  }

  if $need_install or $need_upgrade {
    # If we need to install/upgrade, we need to pull down the package.
    $package_url = "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${awscli2::version}.zip"

    $default_args = [
      '--install-dir',
      $awscli2::install_dir,
      '--bin-dir',
      $awscli2::bin_dir,
    ]

    if $need_upgrade {
      $extra_args = ['--update']
    } else {
      $extra_args = []
    }

    $args = shellquote($default_args+$extra_args);

    # download and extract the package.
    file { '/tmp/umd_awscli2_install':
      ensure => directory,
    }
    -> archive { '/tmp/umd_awscli2.zip':
      ensure       => present,
      source       => $package_url,
      extract      => true,
      extract_path => '/tmp/umd_awscli2_install',
      creates      => '/tmp/umd_awscli2_install/aws/install',
      cleanup      => true,
    }
    # run the installer
    -> exec { 'awscliv2-installer':
      command   => "/tmp/umd_awscli2_install/aws/install ${args}",
      cwd       => '/tmp/umd_awscli2_install',
      logoutput => true,
    }
    # These next 3 (v2/latest+version) are created by the installer
    # but declaring them as resources (after the installer runs)
    # allows us to have puppet purge old installs while
    # still preserving the 'current' install we just did.
    # This model (upgrade first, then remove old) also allows
    # other things on the system using the aws cli to not fail
    # if they happen to run while we are upgrading.
    -> file { "${awscli2::install_dir}/v2":
      ensure  => directory,
      force   => true,
      purge   => true,
      recurse => true,
    }
    -> file { "${$awscli2::install_dir}/v2/current":
      ensure  => link,
    }
    -> file { "${$awscli2::install_dir}/v2/${awscli2::version}":
      ensure  => directory,
    }
    # clean up the install temp dir.
    -> exec { '/usr/bin/rm -rf /tmp/umd_awscli2_install': }
  }
}
