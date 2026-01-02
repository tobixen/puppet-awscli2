require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_140chars')
PuppetLint.configuration.ignore_paths = ['spec/**/*.pp', 'vendor/**/*.pp']

desc 'Run all tests'
task :test => [:lint, :spec]
