# frozen_string_literal: true

require 'fileutils'
require 'open3'
require 'tmpdir'

SCRIPT = File.expand_path('../../files/awscli2-cleanup-old-versions', __dir__)

describe 'files/awscli2-cleanup-old-versions' do
  around(:each) do |example|
    Dir.mktmpdir do |dir|
      @v2 = File.join(dir, 'aws cli', 'v2') # space: the path must survive quoting
      FileUtils.mkdir_p(@v2)
      example.run
    end
  end

  # Create version dirs, oldest first, with strictly increasing mtimes
  def versions(*names)
    names.each_with_index do |name, i|
      path = File.join(@v2, name)
      FileUtils.mkdir_p(File.join(path, 'bin'))
      File.utime(Time.now - 1000 + i, Time.now - 1000 + i, path)
    end
  end

  def point_current_at(target)
    File.symlink(target, File.join(@v2, 'current'))
  end

  def cleanup(retain)
    _out, status = Open3.capture2e(SCRIPT, @v2, retain.to_s)
    status.success?
  end

  def remaining
    Dir.children(@v2).sort
  end

  context 'with an absolute current symlink, as the AWS installer makes it' do
    before(:each) do
      versions('2.1.0', '2.2.0', '2.3.0', '2.4.0')
      point_current_at(File.join(@v2, '2.4.0'))
    end

    it 'keeps the current version and nothing else with retain 0' do
      expect(cleanup(0)).to be true
      expect(remaining).to eq(['2.4.0', 'current'])
    end

    it 'keeps the current version plus one older with retain 1' do
      expect(cleanup(1)).to be true
      expect(remaining).to eq(['2.3.0', '2.4.0', 'current'])
    end

    it 'keeps the current version plus two older with retain 2' do
      expect(cleanup(2)).to be true
      expect(remaining).to eq(['2.2.0', '2.3.0', '2.4.0', 'current'])
    end
  end

  it 'handles a relative current symlink' do
    versions('2.1.0', '2.2.0', '2.3.0')
    point_current_at('2.3.0')
    expect(cleanup(0)).to be true
    expect(remaining).to eq(['2.3.0', 'current'])
  end

  it 'keeps the current version even when it is not the newest' do
    versions('2.1.0', '2.3.0', '2.2.0')
    point_current_at(File.join(@v2, '2.1.0'))
    expect(cleanup(1)).to be true
    expect(remaining).to eq(['2.1.0', '2.2.0', 'current'])
  end

  it 'refuses to delete anything when current does not resolve' do
    versions('2.1.0', '2.2.0')
    point_current_at(File.join(@v2, '9.9.9'))
    expect(cleanup(0)).to be false
    expect(remaining).to eq(['2.1.0', '2.2.0', 'current'])
  end

  it 'refuses a non-numeric retain count' do
    versions('2.1.0', '2.2.0')
    point_current_at('2.2.0')
    expect(cleanup('x')).to be false
    expect(remaining).to eq(['2.1.0', '2.2.0', 'current'])
  end
end
