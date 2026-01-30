require 'spec_helper'

describe 'awscli2' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) { os_facts }

      context 'with default parameters' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('awscli2') }
        it { is_expected.to contain_class('awscli2::install') }
      end

      context 'with ensure => absent' do
        let(:params) { { 'ensure' => 'absent' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('awscli2::uninstall') }
      end
    end
  end

  context 'on Ubuntu 24.04' do
    let(:facts) do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu',
        :operatingsystemrelease => '24.04',
        :kernel          => 'Linux',
        :architecture    => 'x86_64',
      }
    end

    context 'with default parameters (latest version, fresh install)' do
      # No umd_awscli2_version fact = fresh install
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('awscli2::install') }

      it { is_expected.to contain_file('/tmp/umd_awscli2_install').with_ensure('directory') }

      # Fresh install uses archive resources
      it { is_expected.to contain_file('/tmp/umd_awscli2_install/aws-cli-public-key.asc') }
      it { is_expected.to contain_archive('/tmp/umd_awscli2_install/awscli2.zip.sig') }
      it { is_expected.to contain_archive('/tmp/umd_awscli2.zip').with_extract(false) }
      it { is_expected.to contain_exec('awscli2-verify-signature') }
      it { is_expected.to contain_exec('awscli2-extract') }
      it { is_expected.to contain_exec('awscliv2-installer') }
      it { is_expected.to contain_exec('awscli2-cleanup-tmpdir') }

      # Fresh install caches signature for future runs
      it { is_expected.to contain_file('/var/cache/awscli2').with_ensure('directory') }
      it { is_expected.to contain_exec('awscli2-cache-signature') }
    end

    context 'with latest version when already installed (upgrade path)' do
      let(:facts) do
        {
          :osfamily        => 'Debian',
          :operatingsystem => 'Ubuntu',
          :operatingsystemrelease => '24.04',
          :kernel          => 'Linux',
          :architecture    => 'x86_64',
          :umd_awscli2_version => '2.15.0',  # Already installed
        }
      end

      it { is_expected.to compile.with_all_deps }

      # Uses signature caching path with exec/curl instead of archive
      it { is_expected.to contain_exec('awscli2-check-update') }
      it { is_expected.to contain_exec('awscli2-download-package').with_refreshonly(true) }
      it { is_expected.to contain_exec('awscli2-download-signature').with_refreshonly(true) }
      it { is_expected.to contain_exec('awscli2-verify-signature').with_refreshonly(true) }
      it { is_expected.to contain_exec('awscli2-extract').with_refreshonly(true) }
      it { is_expected.to contain_exec('awscliv2-installer').with_refreshonly(true) }
      it { is_expected.to contain_exec('awscli2-cache-signature').with_refreshonly(true) }
      it { is_expected.to contain_exec('awscli2-cleanup-tmpdir').with_refreshonly(true) }

      # Should NOT use archive resources in upgrade path
      it { is_expected.not_to contain_archive('/tmp/umd_awscli2.zip') }
    end

    context 'with verify_signature => false (fresh install)' do
      let(:params) { { 'verify_signature' => false } }

      it { is_expected.to compile.with_all_deps }

      # Without signature verification, should use archive with extract
      it { is_expected.to contain_archive('/tmp/umd_awscli2.zip').with_extract(true) }
      it { is_expected.not_to contain_exec('awscli2-verify-signature') }
      it { is_expected.not_to contain_file('/tmp/umd_awscli2_install/aws-cli-public-key.asc') }
    end

    context 'with verify_signature => false when already installed' do
      let(:facts) do
        {
          :osfamily        => 'Debian',
          :operatingsystem => 'Ubuntu',
          :operatingsystemrelease => '24.04',
          :kernel          => 'Linux',
          :architecture    => 'x86_64',
          :umd_awscli2_version => '2.15.0',
        }
      end
      let(:params) { { 'verify_signature' => false } }

      it { is_expected.to compile.with_all_deps }

      # Uses signature caching but no GPG verification
      it { is_expected.to contain_exec('awscli2-check-update') }
      it { is_expected.to contain_exec('awscli2-extract').with_refreshonly(true) }
      it { is_expected.not_to contain_exec('awscli2-verify-signature') }
    end

    context 'with specific version' do
      let(:params) { { 'version' => '2.15.0' } }

      it { is_expected.to compile.with_all_deps }

      # Uses archive resources for specific version
      it { is_expected.to contain_archive('/tmp/umd_awscli2.zip') }

      # With specific version, should have version cleanup resources
      it { is_expected.to contain_file('/usr/local/aws-cli/v2') }
      it { is_expected.to contain_file('/usr/local/aws-cli/v2/current') }
      it { is_expected.to contain_file('/usr/local/aws-cli/v2/2.15.0') }
    end

    context 'with specific version when same version already installed' do
      let(:facts) do
        {
          :osfamily        => 'Debian',
          :operatingsystem => 'Ubuntu',
          :operatingsystemrelease => '24.04',
          :kernel          => 'Linux',
          :architecture    => 'x86_64',
          :umd_awscli2_version => '2.15.0',  # Same version installed
        }
      end
      let(:params) { { 'version' => '2.15.0' } }

      it { is_expected.to compile.with_all_deps }

      # Should NOT have any installation resources when version matches
      it { is_expected.not_to contain_archive('/tmp/umd_awscli2.zip') }
      it { is_expected.not_to contain_exec('awscliv2-installer') }
    end

    context 'with custom install_dir and bin_dir' do
      let(:params) do
        {
          'version'     => '2.15.0',
          'install_dir' => '/opt/aws-cli',
          'bin_dir'     => '/usr/local/bin',
        }
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_file('/opt/aws-cli/v2') }
    end

    context 'with retain_versions parameter' do
      context 'default value (fresh install with latest)' do
        # Fresh install with version => 'latest'
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('awscli2-cleanup-old-versions').with_command(%r{tail -n \+\$\(\(1 \+ 1\)\)}) }
      end

      context 'custom value on fresh install' do
        let(:params) { { 'retain_versions' => 3 } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('awscli2-cleanup-old-versions').with_command(%r{tail -n \+\$\(\(3 \+ 1\)\)}) }
      end

      context 'zero value (remove all old versions)' do
        let(:params) { { 'retain_versions' => 0 } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('awscli2-cleanup-old-versions').with_command(%r{tail -n \+\$\(\(0 \+ 1\)\)}) }
      end

      context 'on upgrade path with latest' do
        let(:facts) do
          {
            :osfamily        => 'Debian',
            :operatingsystem => 'Ubuntu',
            :operatingsystemrelease => '24.04',
            :kernel          => 'Linux',
            :architecture    => 'x86_64',
            :umd_awscli2_version => '2.15.0',
          }
        end
        let(:params) { { 'retain_versions' => 2 } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_exec('awscli2-cleanup-old-versions').with_refreshonly(true) }
        it { is_expected.to contain_exec('awscli2-cleanup-old-versions').with_command(%r{tail -n \+\$\(\(2 \+ 1\)\)}) }
        it { is_expected.to contain_exec('awscli2-cleanup-old-versions').that_subscribes_to('Exec[awscliv2-installer]') }
      end

      context 'with specific version (no cleanup exec)' do
        let(:params) { { 'version' => '2.15.0', 'retain_versions' => 2 } }

        it { is_expected.to compile.with_all_deps }
        # Specific versions use file purge instead of exec cleanup
        it { is_expected.not_to contain_exec('awscli2-cleanup-old-versions') }
        it { is_expected.to contain_file('/usr/local/aws-cli/v2').with_purge(true) }
      end
    end
  end
end
