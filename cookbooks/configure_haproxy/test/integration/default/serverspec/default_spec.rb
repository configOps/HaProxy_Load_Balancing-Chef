require 'serverspec'
include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

describe 'configure_haproxy::default' do
  it 'installed haproxy' do
    expect(package('haproxy')).to be_installed
  end
end


















