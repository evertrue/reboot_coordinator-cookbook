#
# Cookbook Name:: reboot_coordinator
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

# Installs a custom Ohai plugin to determine if a reboot is pending.

node.set['ohai']['plugins']['reboot_coordinator'] = 'ohai_plugins'
include_recipe 'ohai'

Chef::Log.debug("Value of pending_reboot: #{node['pending_reboot']}")

if node['reboot_coordinator']['zk_base_node']
  chef_gem 'zk' do
    compile_time true
  end

  ruby_block 'clear_reboot_lock' do
    block do
      RebootCoordinator::Helpers::RebootLock.new(
        node['fqdn'],
        node['reboot_coordinator']
      ).clear
    end
  end

  ruby_block 'set_reboot_lock' do
    block do
      rl = RebootCoordinator::Helpers::RebootLock.new(
        node['fqdn'],
        node['reboot_coordinator']
      )
      rl.set
    end
    action :nothing
  end
end

reboot 'catchall_reboot_handler' do
  action     :request_reboot
  reason     'Chef requested a reboot in reboot_coordinator::default'
  delay_mins node['reboot_coordinator']['reboot_delay']
  only_if do
    node['reboot_coordinator']['reboot_permitted'] &&
      node['pending_reboot'] &&
      node['reboot_coordinator']['acceptable_reboot_times'].include?(Time.now.hour)
  end
  not_if do
    Chef::Log.debug('In catchall_reboot_handler not_if block...')
    node['reboot_coordinator']['zk_base_node'] && (
      RebootCoordinator::Helpers::RebootLock.new(
        node['fqdn'],
        node['reboot_coordinator']
      ).exists?
    )
  end
  notifies :run, 'ruby_block[set_reboot_lock]' if node['reboot_coordinator']['zk_base_node']
end
