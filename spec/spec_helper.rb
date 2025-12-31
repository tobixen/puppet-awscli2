require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

include RspecPuppetFacts

RSpec.configure do |c|
  c.default_facts = {
    :osfamily        => 'Debian',
    :operatingsystem => 'Ubuntu',
    :operatingsystemrelease => '24.04',
    :kernel          => 'Linux',
    :architecture    => 'x86_64',
  }
end
