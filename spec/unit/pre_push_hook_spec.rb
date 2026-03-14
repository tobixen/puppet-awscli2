# frozen_string_literal: true

require 'open3'
require 'tmpdir'

HOOK = File.expand_path('../../.githooks/pre-push', __dir__)

describe '.githooks/pre-push' do
  around(:each) do |example|
    Dir.mktmpdir do |dir|
      @repo = dir
      git('init', '-q')
      commit_version('1.0.0')
      @old = git('rev-parse', 'HEAD').strip
      commit_version('2.0.0')
      @new = git('rev-parse', 'HEAD').strip
      example.run
    end
  end

  def git(*args)
    out, status = Open3.capture2e('git', '-c', 'user.name=t', '-c', 'user.email=t@t', *args, chdir: @repo)
    raise out unless status.success?
    out
  end

  def commit_version(version)
    File.write(File.join(@repo, 'metadata.json'), %({\n  "version": "#{version}"\n}\n))
    git('add', 'metadata.json')
    git('commit', '-q', '-m', version)
  end

  def push(local_ref, sha, remote_ref)
    input = "#{local_ref} #{sha} #{remote_ref} #{'0' * 40}\n"
    _out, status = Open3.capture2e(HOOK, 'origin', 'url', stdin_data: input, chdir: @repo)
    status.success?
  end

  it 'accepts a tag matching metadata.json at the tagged commit' do
    expect(push('refs/tags/v2.0.0', @new, 'refs/tags/v2.0.0')).to be true
  end

  it 'rejects a tag not matching metadata.json at the tagged commit' do
    expect(push('refs/tags/v1.0.0', @new, 'refs/tags/v1.0.0')).to be false
  end

  it 'checks the tagged commit rather than the working tree' do
    expect(push('refs/tags/v1.0.0', @old, 'refs/tags/v1.0.0')).to be true
    expect(push('refs/tags/v2.0.0', @old, 'refs/tags/v2.0.0')).to be false
  end

  it 'checks the remote ref name, not just the local one' do
    expect(push('HEAD', @new, 'refs/tags/v9.9.9')).to be false
  end

  it 'ignores tag deletions' do
    expect(push('(delete)', '0' * 40, 'refs/tags/v9.9.9')).to be true
  end

  it 'ignores branch pushes' do
    expect(push('refs/heads/main', @old, 'refs/heads/main')).to be true
  end
end
