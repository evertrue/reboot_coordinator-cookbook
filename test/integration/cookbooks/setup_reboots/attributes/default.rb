override['reboot_coordinator']['acceptable_reboot_times'] = 0..23
override['reboot_coordinator']['pre_reboot_commands'] = {
  'reboot_after_20_secs' => 'sleep 20',
  'verify_environment' => 'if [ ! $TEST_VAR ]; then echo "TEST_VAR not set"; exit 1; fi'
}
