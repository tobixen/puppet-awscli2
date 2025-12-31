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

    context 'with default parameters (latest version)' do
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('awscli2::install') }

      it { is_expected.to contain_file('/tmp/umd_awscli2_install').with_ensure('directory') }

      # With verify_signature => true (default), should have GPG verification resources
      it { is_expected.to contain_file('/tmp/umd_awscli2_install/aws-cli-public-key.asc') }
      it { is_expected.to contain_archive('/tmp/umd_awscli2_install/awscli2.zip.sig') }
      it { is_expected.to contain_archive('/tmp/umd_awscli2.zip').with_extract(false) }
      it { is_expected.to contain_exec('awscli2-verify-signature') }
      it { is_expected.to contain_exec('awscli2-extract') }
      it { is_expected.to contain_exec('awscliv2-installer') }
      it { is_expected.to contain_exec('awscli2-cleanup-tmpdir') }
    end

    context 'with verify_signature => false' do
      let(:params) { { 'verify_signature' => false } }

      it { is_expected.to compile.with_all_deps }

      # Without signature verification, should use archive with extract
      it { is_expected.to contain_archive('/tmp/umd_awscli2.zip').with_extract(true) }
      it { is_expected.not_to contain_exec('awscli2-verify-signature') }
      it { is_expected.not_to contain_file('/tmp/umd_awscli2_install/aws-cli-public-key.asc') }
    end

    context 'with specific version' do
      let(:params) { { 'version' => '2.15.0' } }

      it { is_expected.to compile.with_all_deps }

      # With specific version, should have version cleanup resources
      it { is_expected.to contain_file('/usr/local/aws-cli/v2') }
      it { is_expected.to contain_file('/usr/local/aws-cli/v2/current') }
      it { is_expected.to contain_file('/usr/local/aws-cli/v2/2.15.0') }
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
  end
end
