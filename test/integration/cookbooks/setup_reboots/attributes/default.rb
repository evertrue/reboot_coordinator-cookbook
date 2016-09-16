override['reboot_coordinator']['acceptable_reboot_times'] = 0..23
override['reboot_coordinator']['pre_reboot_commands'] = {
  'reboot_after_20_secs' => 'sleep 20'
}
