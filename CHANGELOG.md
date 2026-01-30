# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2026-01-30

### Added
- New `retain_versions` parameter to control how many old AWS CLI versions to keep when using `version => 'latest'`. Defaults to 1 for rollback capability. Set to 0 to remove all old versions immediately after upgrade.

## [0.4.0] - 2026-01-02

This release represents a fork of the original [umd-awscli2](https://forge.puppet.com/modules/umd/awscli2) module by Eric Sturdivant at University of Maryland.

### Added
- GPG signature verification of AWS CLI packages using the official AWS public key
- Support for `version => 'latest'` to always install the newest AWS CLI version (now the default)
- Signature caching to avoid unnecessary downloads when using 'latest' - only re-downloads when the signature changes
- Comprehensive rspec-puppet test suite
- GitHub Actions CI for testing on Puppet 7 and 8
- GitHub Actions workflow for auto-publishing to Puppet Forge

### Changed
- Version parameter now defaults to 'latest' instead of being required
- Module renamed to `tobixen-awscli2`
- Expanded OS support: Ubuntu 20.04/24.04, RedHat/CentOS 7/8/9

## [0.3.0] and earlier

See the original [umd-awscli2](https://forge.puppet.com/modules/umd/awscli2) module for previous history.
