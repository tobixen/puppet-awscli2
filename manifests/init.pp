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
#   The directory to store symlinks to eecutables for the AWS CLI.
#   Defaults to `/usr/bin`.
#
class awscli2 (
  String[1]                 $version,
  Enum['absent', 'present'] $ensure = 'present',
  String[1]                 $install_dir = '/usr/local/aws-cli',
  String[1]                 $bin_dir = '/usr/bin',
) {
  if $ensure == 'absent' {
    contain awscli2::uninstall
  } else {
    contain awscli2::install
  }
}
