#
# Cookbook Name:: reboot_coordinator
# Recipe:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

include_recipe 'build-essential'
include_recipe 'reboot_coordinator::ohai'
include_recipe 'reboot_coordinator::legacy' if platform_family?('debian') &&
                                               node['platform_version'].to_i < 14

package 'jq'

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

# For various reasons (JSON being one of them), the reboot times value might
# come in as a string
acceptable_reboot_times =
  if node['reboot_coordinator']['acceptable_reboot_times'].respond_to?(:match) &&
    node['reboot_coordinator']['acceptable_reboot_times'].match(/\d+\.\.\d+/) # Ensure it's a range
    Range.new(*node['reboot_coordinator']['acceptable_reboot_times'].split('..').map(&:to_i))
  else
    node['reboot_coordinator']['acceptable_reboot_times']
  end

Chef::Log.debug('State of reboot triggers:')
Chef::Log.debug("reboot_permitted: #{node['reboot_coordinator']['reboot_permitted']}")
Chef::Log.debug("pending_reboot: #{node['pending_reboot']}")
Chef::Log.debug(
  'acceptable_reboot_times: ' \
  "#{acceptable_reboot_times.include?(Time.now.hour)}"
)

node['reboot_coordinator']['pre_reboot_commands'].each do |cmd_name, cmd|
  # The idea here to run these commands before a reboot, but also to ensure
  # that a reboot does not proceed (because Chef bails) if these don't complete
  # successfully
  execute "pre_reboot_command #{cmd_name}" do
    command cmd
    environment node['etc_environment'] if node['etc_environment']
    action  :nothing
    only_if do
      node['reboot_coordinator']['reboot_permitted'] &&
        node['pending_reboot'] &&
        acceptable_reboot_times.include?(Time.now.hour)
    end
  end
end

# This helps us avoid running the reboot on the same run where we set up the reboot coordinator,
# which can sometimes be a problem if pre-reboot commands won't run cleanly until after a full
# convergence.
#
node.set['reboot_coordinator']['convergences_since_creation'] =
  (node['reboot_coordinator']['convergences_since_creation'] || 0) + 1

reboot 'catchall_reboot_handler' do
  node['reboot_coordinator']['pre_reboot_resources'].each do |pr_resource, pr_resource_conf|
    notifies pr_resource_conf['action'], pr_resource, pr_resource_conf['when']
  end
  node['reboot_coordinator']['pre_reboot_commands'].each_key do |cmd_name|
    notifies :run, "execute[pre_reboot_command #{cmd_name}]", :before
  end
  action     :request_reboot
  reason     'Chef requested a reboot in reboot_coordinator::default'
  delay_mins node['reboot_coordinator']['reboot_delay']
  only_if do
    node['reboot_coordinator']['reboot_permitted'] &&
      node['pending_reboot'] &&
      node['reboot_coordinator']['convergences_since_creation'] > 1 &&
      acceptable_reboot_times.include?(Time.now.hour)
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
