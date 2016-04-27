require 'spec_helper'

describe 'configure_haproxy::default' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'installs the haproxy package' do
    expect(chef_run).to install_package('haproxy')
  end

  it 'writes the haproxy conf template' do
    expect(chef_run).to create_template('/etc/haproxy/haproxy.conf')

  end
end


