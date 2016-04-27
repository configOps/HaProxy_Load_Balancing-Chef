require 'spec_helper'

describe 'configure_nginx::default' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'installs the nginx package' do
    expect(chef_run).to install_package('haproxy')
  end


end


