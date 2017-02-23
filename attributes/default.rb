override['build-essential']['compile_time'] = true
default['reboot_coordinator']['reboot_permitted'] = true

# A table to help ensure that two nodes in the same cluster don't reboot at the
# same time. The ranges represent hours, so nodes in us-east-1a are allowed
# to reboot between 00:00 and 04:59, etc.
reboot_times_chart = {
  'us-east-1a' => 0..4,
  'us-east-1b' => 6..10,
  'us-east-1c' => 12..16,
  'us-east-1d' => 18..22
}

default['reboot_coordinator']['acceptable_reboot_times'] =
  reboot_times_chart[node['ec2']['placement_availability_zone']]
default['reboot_coordinator']['reboot_delay'] = 5
default['reboot_coordinator']['reboot_interval'] = 300
default['reboot_coordinator']['zk_hosts'] = ['localhost:2181']
default['reboot_coordinator']['pre_reboot_commands'] = {}
default['reboot_coordinator']['pre_reboot_resources'] = {}
