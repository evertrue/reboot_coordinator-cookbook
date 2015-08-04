module RebootCoordinator
  module Helpers
    class RebootLock
      def clear
        return true unless zk.exists?("#{@base_node}/lock")
        return false unless zk.get("#{@base_node}/lock").first == @fqdn
        Chef::Log.debug('Clearing reboot lock')
        zk.delete("#{@base_node}/lock")
      end

      def exists?
        return false unless zk.exists?("#{@base_node}/lock")
        Chef::Log.debug('A reboot lock exists')
        if lock.first == @fqdn
          Chef::Log.debug('...but that reboot lock belongs to us')
          return false
        end
        Chef::Log.debug("Reboot lock is for another host: #{lock.first}")
        if expired?
          Chef::Log.debug('Found an expired reboot lock')
          return false
        else
          Chef::Log.debug('Found an active reboot lock')
          return true
        end
      end

      def set
        if zk.exists?("#{@base_node}/lock")
          if lock.first != @fqdn && !expired?
            fail 'Tried to create a lock when a fresh one already exists'
          end
          Chef::Log.debug('Deleting reboot lock')
          zk.delete("#{@base_node}/lock")
        end
        Chef::Log.debug('Creating a new reboot lock')
        zk.create("#{@base_node}/lock", @fqdn, or: :set)
      end

      def expired?
        n_time = lock.last.ctime / 1000
        age = Time.now.to_i - n_time
        Chef::Log.debug("Reboot lock age: #{age} (interval is #{@interval})")
        age > @interval
      end

      def lock
        zk.get("#{@base_node}/lock")
      end

      def initialize(fqdn, options)
        @fqdn      = fqdn
        @zk_hosts  = options['zk_hosts']
        @base_node = options['zk_base_node']
        @interval  = options['reboot_interval']
      end

      private

      def zk
        @zk ||= begin
          require 'zk'
          ::ZK::Client.new(@zk_hosts.join(','))
        end
      end
    end
  end
end
