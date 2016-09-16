#
# Cookbook Name:: reboot_coordinator
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'reboot_coordinator::ohai'

Chef::Log.debug("Value of pending_reboot: #{node['pending_reboot']}")

if node['reboot_coordinator']['zk_base_node']
  Chef::Log.debug('reboot_coordinator is using zookeeper hosts: ' \
    "#{node['reboot_coordinator']['zk_hosts'].inspect}")
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

Chef::Log.debug('State of reboot triggers:')
Chef::Log.debug("reboot_permitted: #{node['reboot_coordinator']['reboot_permitted']}")
Chef::Log.debug("pending_reboot: #{node['pending_reboot']}")
Chef::Log.debug(
  'acceptable_reboot_times: ' \
  "#{node['reboot_coordinator']['acceptable_reboot_times'].include?(Time.now.hour)}"
)

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
