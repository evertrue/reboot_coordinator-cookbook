# reboot_coordinator

A cookbook that should help ensure that no two nodes in the same cluster (with the same value for `node['reboot_coordinator']['zk_base_node']`) are rebooted at the same time.
