#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with awscli2](#setup)
    * [What awscli2 affects](#what-awscli2-affects)
    * [Requirements](#requirements)
4. [Usage - Configuration options and additional functionality](#usage)
    * [Required Parameters](#required-parameters)
    * [Optional Parameters](#optional-parameters)
    * [Example](#example)
5. [Limitations - OS compatibility, etc.](#limitations)

## Overview

This module installs (or upgrades, or un-installs) the AWS CLI v2. AWS has packaged up v2 of the CLI with all dependencies included (but not packaged it as a deb or RPM).

## Module Description

This module, by default, will place symlinks in `/usr/bin` (rather than the
AWS default of `/usr/local/bin`. This was chosen because the previous AWS CLI
command (provided by redhat) was installed into that location, and we do
not want to break any scripts that do not have `/usr/local/bin` in their path
or may have hard-coded `/usr/bin/aws`.

This module requires the manual specification of the version of the CLI to
install. This was done to prevent having to download the `latest` zip file
from AWS on every puppet run just to see if it has been updated. This module
will remove older versions after a successful upgrade to keep disk space down.

By default, this module verifies the GPG signature of the downloaded package
using the official AWS CLI public key, as recommended by AWS. This ensures
the integrity and authenticity of the installer. See:
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

This module delivers a custom fact (`umd_awscliv2_version`) which is used to
determine if an upgrade or clean install is needed (it will do nothing if
the requested version is already installed).

This module is not a complete replacement for a package management system, and
it is possible for it to fail to un-install older versions on upgrade or
`absent`. In particular, the currently installed version fact is based on
the current value of `$bin_path`, and changing this parameter after an install
has happened will leave the previous installation abandoned.

## Setup

### What awscli2 affects

* By default, it will install the CLI into `/usr/local/aws-cli`.
* By default, it will symlink binaries (`aws`, `aws_completer`) into `/usr/bin`.

### Requirements

* `gpg` - Required for signature verification (enabled by default).
* `unzip` - Required for extracting the installer when signature verification is enabled.

## Usage

Include the `awscli2` class and define the following parameters as required:

### Required Parameters

* `version`: The version of the CLI to install, e.g. `'2.15.0'`

### Optional Parameters

* `ensure`: Set to `absent` to un-install the AWS CLI.
* `install_dir`: Path to install the CLI into. Defaults to `/usr/local/aws-cli`.
* `bin_dir`: Path to create symlinks to binaries. Defaults to `/usr/bin`.
* `verify_signature`: Whether to verify the GPG signature of the downloaded package. Defaults to `true`.

### Example

```yaml
---
classes:
  - awscli2
awscli2::version: '2.15.0'
```

