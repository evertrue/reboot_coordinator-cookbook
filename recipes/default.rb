#
# Cookbook Name:: reboot_coordinator
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

chef_gem 'zk'

if node['reboot_coordinator']['zk_base_node']
  node.set['reboot_coordinator']['zk_hosts'] = (
    if node['et_mesos_slave']['mocking']
      ['localhost:2181']
    else
      search(
        :node,
        "chef_environment:#{node.chef_environment} AND " \
        'roles:zookeeper'
      ).map { |n| "#{n[:fqdn]}:2181" }
    end
  )

  ruby_block 'clear_reboot_lock' do
    block do
      RebootCoordinator::Helpers::RebootLock.new(
        node['reboot_coordinator']['zk_hosts'],
        node['reboot_coordinator']['zk_base_node'],
        node['fqdn'],
        node['reboot_coordinator']['reboot_interval']
      ).clear
    end
  end

  ruby_block 'set_reboot_lock' do
    block do
      rl = RebootCoordinator::Helpers::RebootLock.new(
        node['reboot_coordinator']['zk_hosts'],
        node['reboot_coordinator']['zk_base_node'],
        node['fqdn'],
        node['reboot_coordinator']['reboot_interval']
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
      File.exist?('/var/run/reboot-required') &&
      node['reboot_coordinator']['acceptable_reboot_times'].include?(Time.now.hour)
  end
  not_if do
    Chef::Log.debug('In catchall_reboot_handler not_if block...')
    node['reboot_coordinator']['zk_base_node'] && (
      RebootCoordinator::Helpers::RebootLock.new(
        node['reboot_coordinator']['zk_hosts'],
        node['reboot_coordinator']['zk_base_node'],
        node['fqdn'],
        node['reboot_coordinator']['reboot_interval']
      ).exists?
    )
  end
  notifies :run, 'ruby_block[set_reboot_lock]' if node['reboot_coordinator']['zk_base_node']
end
