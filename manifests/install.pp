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
  $is_installed = $facts['umd_awscli2_version'] != undef
  $version_matches = $is_installed and ($facts['umd_awscli2_version'] == $awscli2::version)

  # Determine action needed
  if $awscli2::version == 'latest' {
    # For 'latest', we need to check if an update is available
    # Fresh install always proceeds; upgrades use signature comparison
    $need_install = !$is_installed
    $need_upgrade = $is_installed
    $use_sig_cache = $is_installed  # Only use signature caching for upgrades
  } elsif $is_installed and !$version_matches {
    # Installed version differs from requested
    $need_install = false
    $need_upgrade = true
    $use_sig_cache = false
  } elsif !$is_installed {
    # Nothing installed yet
    $need_install = true
    $need_upgrade = false
    $use_sig_cache = false
  } else {
    # Version matches, nothing to do
    $need_install = false
    $need_upgrade = false
    $use_sig_cache = false
  }

  if $need_install or $need_upgrade {
    # If we need to install/upgrade, we need to pull down the package.
    # When version is 'latest', use the non-versioned URL.
    if $awscli2::version == 'latest' {
      $package_url = 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip'
    } else {
      $package_url = "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${awscli2::version}.zip"
    }
    $signature_url = "${package_url}.sig"

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

    # Create temp directory for installation
    file { '/tmp/umd_awscli2_install':
      ensure => directory,
    }

    # For 'latest' with existing install, use signature caching to avoid
    # unnecessary downloads. We compare the current signature with a cached
    # copy and only proceed if they differ.
    if $use_sig_cache {
      # Ensure cache directory exists
      file { '/var/cache/awscli2':
        ensure => directory,
      }

      # Check if update is available by comparing signatures
      # This exec only runs if the signatures differ (or no cache exists)
      # It then notifies the download chain
      exec { 'awscli2-check-update':
        command => '/bin/true',
        unless  => "/usr/bin/curl -sf '${signature_url}' | /usr/bin/cmp -s - /var/cache/awscli2/latest.sig",
        require => File['/var/cache/awscli2'],
        notify  => Exec['awscli2-download-package'],
      }

      # Download package - only when notified by check-update
      exec { 'awscli2-download-package':
        command     => "/usr/bin/curl -fL '${package_url}' -o /tmp/umd_awscli2.zip",
        refreshonly => true,
        require     => File['/tmp/umd_awscli2_install'],
      }

      # Download signature - only when notified
      exec { 'awscli2-download-signature':
        command     => "/usr/bin/curl -fL '${signature_url}' -o /tmp/umd_awscli2_install/awscli2.zip.sig",
        refreshonly => true,
        require     => File['/tmp/umd_awscli2_install'],
        subscribe   => Exec['awscli2-download-package'],
      }

      if $awscli2::verify_signature {
        # Deploy the AWS CLI public key for signature verification
        file { '/tmp/umd_awscli2_install/aws-cli-public-key.asc':
          ensure  => file,
          source  => 'puppet:///modules/awscli2/aws-cli-public-key.asc',
          mode    => '0444',
          require => File['/tmp/umd_awscli2_install'],
        }

        # Verify the GPG signature - only when notified
        exec { 'awscli2-verify-signature':
          command     => '/usr/bin/gpg --no-default-keyring --keyring /tmp/umd_awscli2_install/aws-cli-keyring.gpg --import /tmp/umd_awscli2_install/aws-cli-public-key.asc && /usr/bin/gpg --no-default-keyring --keyring /tmp/umd_awscli2_install/aws-cli-keyring.gpg --verify /tmp/umd_awscli2_install/awscli2.zip.sig /tmp/umd_awscli2.zip',
          cwd         => '/tmp/umd_awscli2_install',
          logoutput   => true,
          refreshonly => true,
          require     => File['/tmp/umd_awscli2_install/aws-cli-public-key.asc'],
          subscribe   => Exec['awscli2-download-signature'],
        }

        # Extract the zip file after verification - only when notified
        exec { 'awscli2-extract':
          command     => '/usr/bin/unzip -o /tmp/umd_awscli2.zip -d /tmp/umd_awscli2_install',
          refreshonly => true,
          subscribe   => Exec['awscli2-verify-signature'],
        }
      } else {
        # Extract without verification - only when notified
        exec { 'awscli2-extract':
          command     => '/usr/bin/unzip -o /tmp/umd_awscli2.zip -d /tmp/umd_awscli2_install',
          refreshonly => true,
          subscribe   => Exec['awscli2-download-package'],
        }
      }

      # Run the installer - only when notified
      exec { 'awscliv2-installer':
        command     => "/tmp/umd_awscli2_install/aws/install ${args}",
        cwd         => '/tmp/umd_awscli2_install',
        logoutput   => true,
        refreshonly => true,
        subscribe   => Exec['awscli2-extract'],
      }

      # Cache the signature after successful install
      exec { 'awscli2-cache-signature':
        command     => '/bin/cp /tmp/umd_awscli2_install/awscli2.zip.sig /var/cache/awscli2/latest.sig',
        refreshonly => true,
        subscribe   => Exec['awscliv2-installer'],
      }

      # Clean up the zip file
      exec { 'awscli2-cleanup-zip':
        command     => '/usr/bin/rm -f /tmp/umd_awscli2.zip',
        refreshonly => true,
        subscribe   => Exec['awscliv2-installer'],
      }

      # Clean up the temp dir
      exec { 'awscli2-cleanup-tmpdir':
        command     => '/usr/bin/rm -rf /tmp/umd_awscli2_install',
        refreshonly => true,
        subscribe   => Exec['awscli2-cache-signature'],
      }
    } else {
      # Standard installation path (fresh install or specific version)
      if $awscli2::verify_signature {
        # Deploy the AWS CLI public key for signature verification
        file { '/tmp/umd_awscli2_install/aws-cli-public-key.asc':
          ensure  => file,
          source  => 'puppet:///modules/awscli2/aws-cli-public-key.asc',
          mode    => '0444',
          require => File['/tmp/umd_awscli2_install'],
        }

        # Download the signature file
        archive { '/tmp/umd_awscli2_install/awscli2.zip.sig':
          ensure  => present,
          source  => $signature_url,
          extract => false,
          require => File['/tmp/umd_awscli2_install'],
        }

        # Download the zip file (without extracting yet)
        archive { '/tmp/umd_awscli2.zip':
          ensure  => present,
          source  => $package_url,
          extract => false,
          require => File['/tmp/umd_awscli2_install'],
        }

        # Verify the GPG signature
        exec { 'awscli2-verify-signature':
          command   => '/usr/bin/gpg --no-default-keyring --keyring /tmp/umd_awscli2_install/aws-cli-keyring.gpg --import /tmp/umd_awscli2_install/aws-cli-public-key.asc && /usr/bin/gpg --no-default-keyring --keyring /tmp/umd_awscli2_install/aws-cli-keyring.gpg --verify /tmp/umd_awscli2_install/awscli2.zip.sig /tmp/umd_awscli2.zip',
          cwd       => '/tmp/umd_awscli2_install',
          logoutput => true,
          require   => [
            File['/tmp/umd_awscli2_install/aws-cli-public-key.asc'],
            Archive['/tmp/umd_awscli2_install/awscli2.zip.sig'],
            Archive['/tmp/umd_awscli2.zip'],
          ],
        }

        # Extract the zip file after verification
        exec { 'awscli2-extract':
          command => '/usr/bin/unzip -o /tmp/umd_awscli2.zip -d /tmp/umd_awscli2_install',
          creates => '/tmp/umd_awscli2_install/aws/install',
          require => Exec['awscli2-verify-signature'],
        }

        # Clean up the zip file
        exec { 'awscli2-cleanup-zip':
          command     => '/usr/bin/rm -f /tmp/umd_awscli2.zip',
          refreshonly => true,
          subscribe   => Exec['awscli2-extract'],
        }

        # Run the installer
        exec { 'awscliv2-installer':
          command   => "/tmp/umd_awscli2_install/aws/install ${args}",
          cwd       => '/tmp/umd_awscli2_install',
          logoutput => true,
          require   => Exec['awscli2-extract'],
        }
      } else {
        # Skip signature verification - download and extract directly
        archive { '/tmp/umd_awscli2.zip':
          ensure       => present,
          source       => $package_url,
          extract      => true,
          extract_path => '/tmp/umd_awscli2_install',
          creates      => '/tmp/umd_awscli2_install/aws/install',
          cleanup      => true,
          require      => File['/tmp/umd_awscli2_install'],
        }

        # Run the installer
        exec { 'awscliv2-installer':
          command   => "/tmp/umd_awscli2_install/aws/install ${args}",
          cwd       => '/tmp/umd_awscli2_install',
          logoutput => true,
          require   => Archive['/tmp/umd_awscli2.zip'],
        }
      }

      # When using a specific version, we can purge old versions from the
      # install directory while preserving the current install. This is done
      # by declaring the version directory as a resource after the installer runs.
      # When using 'latest', we skip purging since we don't know the version
      # directory name at Puppet compile time.
      if $awscli2::version != 'latest' {
        # These next 3 (v2/latest+version) are created by the installer
        # but declaring them as resources (after the installer runs)
        # allows us to have puppet purge old installs while
        # still preserving the 'current' install we just did.
        # This model (upgrade first, then remove old) also allows
        # other things on the system using the aws cli to not fail
        # if they happen to run while we are upgrading.
        file { "${awscli2::install_dir}/v2":
          ensure  => directory,
          force   => true,
          purge   => true,
          recurse => true,
          require => Exec['awscliv2-installer'],
        }

        file { "${awscli2::install_dir}/v2/current":
          ensure  => link,
          require => File["${awscli2::install_dir}/v2"],
        }

        file { "${awscli2::install_dir}/v2/${awscli2::version}":
          ensure  => directory,
          require => File["${awscli2::install_dir}/v2/current"],
        }

        # clean up the install temp dir.
        exec { 'awscli2-cleanup-tmpdir':
          command => '/usr/bin/rm -rf /tmp/umd_awscli2_install',
          require => File["${awscli2::install_dir}/v2/${awscli2::version}"],
        }
      } else {
        # Fresh install with 'latest' - cache signature for future runs
        file { '/var/cache/awscli2':
          ensure => directory,
        }

        exec { 'awscli2-cache-signature':
          command => "/usr/bin/curl -fL '${signature_url}' -o /var/cache/awscli2/latest.sig",
          require => [Exec['awscliv2-installer'], File['/var/cache/awscli2']],
        }

        # clean up the install temp dir.
        exec { 'awscli2-cleanup-tmpdir':
          command => '/usr/bin/rm -rf /tmp/umd_awscli2_install',
          require => Exec['awscli2-cache-signature'],
        }
      }
    }
  }
}
