Ohai.plugin(:PendingReboot) do
  provides 'pending_reboot'

  collect_data(:linux) do
    pending_reboot File.exist?('/var/run/reboot-required')
  end
end
