#
# Cookbook Name:: reboot_coordinator
# Recipe:: legacy
#
# Copyright (c) 2017 Evertrue, All Rights Reserved.

# This recipe is needed for Ubuntu < 14 because that's when the `jq` package was added

apt_repository 'brightbox-ruby' do
  uri 'http://archive.ubuntu.com/ubuntu'
  distribution "#{node['lsb']['codename']}-backports"
  components %w(main restricted universe multiverse)
end
