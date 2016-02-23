# Installs a custom Ohai plugin to determine if a reboot is pending.

node.set['ohai']['plugins']['reboot_coordinator'] = 'ohai_plugins'
include_recipe 'ohai'
