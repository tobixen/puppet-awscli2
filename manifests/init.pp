# Class: awscli2
# ===========================
#
# Installs the AWS CLI version 2.
#
# Parameters
# ----------
#
# @param version
#   Version of the AWS CLI to install. E.g. "2.0.28"
#
# @param ensure
#   Set to `absent` to un-install the AWS CLI. Set to `present` to
#   install it.
#
# @param install_dir
#   Path to install the AWS CLI into. Defaults to `/usr/local/aws-cli`.
#
# @param bin_dir
#   The directory to store symlinks to executables for the AWS CLI.
#   Defaults to `/usr/bin`.
#
# @param verify_signature
#   Whether to verify the GPG signature of the downloaded package.
#   Defaults to `true`. Requires `gpg` and `unzip` to be installed.
#   See: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
#
class awscli2 (
  String[1]                 $version,
  Enum['absent', 'present'] $ensure = 'present',
  String[1]                 $install_dir = '/usr/local/aws-cli',
  String[1]                 $bin_dir = '/usr/bin',
  Boolean                   $verify_signature = true,
) {
  if $ensure == 'absent' {
    contain awscli2::uninstall
  } else {
    contain awscli2::install
  }
}
