require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_140chars')
PuppetLint.configuration.ignore_paths = ['spec/**/*.pp', 'vendor/**/*.pp']

desc 'Configure git to use the project hooks in .githooks/'
task :setup do
  sh 'git config core.hooksPath .githooks'
  puts 'Git hooks configured. Run "bundle exec rake setup" once per clone.'
end

desc 'Run all tests'
task :test => [:lint, :spec]
