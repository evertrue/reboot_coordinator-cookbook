require 'spec_helper'
require_relative '../../../libraries/helpers'

describe RebootCoordinator::Helpers::RebootLock do
  before(:each) do
    @zk_hosts = ['169.254.169.254:2181']
    @base_node = '/rspec_reboot_node'
    @my_node_fqdn = 'my.node.fqdn.com'
    @reboot_interval = 300

    @rl = RebootCoordinator::Helpers::RebootLock.new(
      @my_node_fqdn,
      'zk_hosts' => ['169.254.169.254:2181'],
      'zk_base_node' => @base_node,
      'reboot_interval' => @reboot_interval
    )
    @zk_client = instance_double('zk_client')
    allow(@rl).to receive(:zk).and_return(@zk_client)
  end

  describe '#clear' do
    context 'when no lock exists at all' do
      before(:each) do
        allow(@zk_client).to receive(:exists?).with("#{@base_node}/lock").and_return(false)
      end

      it 'returns true when clearing a lock' do
        expect(@rl.clear).to eq(true)
      end
    end

    context 'when a lock exists but it was created by this client' do
      before(:each) do
        expect(@zk_client).to receive(:exists?).with("#{@base_node}/lock").and_return(true)
        allow(@zk_client).to receive(:get).with("#{@base_node}/lock").and_return([@my_node_fqdn])
      end

      it 'prints useful debug output' do
        expect(Chef::Log).to receive(:debug).with('Clearing reboot lock')
        allow(@zk_client).to receive(:delete).with("#{@base_node}/lock")
      end

      it 'deletes the lock' do
        expect(@zk_client).to receive(:delete).with("#{@base_node}/lock")
      end

      after(:each) do
        @rl.clear
      end
    end

    context "when another client's lock exists" do
      before(:each) do
        expect(@zk_client).to receive(:exists?).with("#{@base_node}/lock").and_return(true)
        allow(@zk_client).to receive(:get).with("#{@base_node}/lock").and_return(['some_other_fqdn'])
      end

      it 'does not delete the lock' do
        expect(@zk_client).to_not receive(:delete).with("#{@base_node}/lock")
        @rl.clear
      end

      it 'returns false' do
        expect(@rl.clear).to eq(false)
      end
    end
  end

  describe '#exists?' do
    context 'when no lock exists' do
      before(:each) do
        expect(@zk_client).to receive(:exists?).with("#{@base_node}/lock").and_return(false)
      end

      it 'returns false' do
        expect(@rl.exists?).to eq(false)
      end
    end

    context 'when a lock exists but it was created by this client' do
      before(:each) do
        allow(@zk_client).to receive(:exists?).with("#{@base_node}/lock").and_return(true)
        allow(@rl).to receive(:lock).and_return([@my_node_fqdn])
      end

      describe 'debug output' do
        before(:each) do
          allow(Chef::Log).to receive(:debug).and_call_original
        end

        it 'indicates lock exits' do
          expect(Chef::Log).to receive(:debug).with('A reboot lock exists')
        end

        it 'indicates that the lock belongs to this client' do
          expect(Chef::Log).to receive(:debug).with('...but that reboot lock belongs to us')
        end

        after(:each) do
          @rl.exists?
        end
      end

      it 'returns false' do
        expect(@rl.exists?).to eq(false)
      end
    end

    context "when another client's lock exists" do
      @some_other_fqdn = 'some_other_fqdn'

      before(:each) do
        expect(@zk_client).to receive(:exists?).with("#{@base_node}/lock").and_return(true)
        allow(@rl).to receive(:lock).and_return([@some_other_fqdn])
      end

      describe 'debug output' do
        before(:each) do
          allow(Chef::Log).to receive(:debug).and_call_original
          allow(@rl).to receive(:expired?)
        end

        it 'indicates the lock is for another host' do
          expect(Chef::Log).to receive(:debug).with(
            "Reboot lock is for another host: #{@some_other_fqdn}"
          )
        end

        after(:each) do
          @rl.exists?
        end
      end

      context 'and that lock is expired' do
        before(:each) do
          allow(@rl).to receive(:expired?).and_return(true)
        end

        describe 'debug output' do
          before(:each) do
            allow(Chef::Log).to receive(:debug).and_call_original
          end

          it 'indicates an expired lock' do
            expect(Chef::Log).to receive(:debug).with('Found an expired reboot lock')
          end

          after(:each) do
            @rl.exists?
          end
        end

        it 'returns false' do
          expect(@rl.exists?).to eq(false)
        end
      end

      context 'and that lock is still valid' do
        before(:each) do
          allow(@rl).to receive(:expired?).and_return(false)
        end

        context 'debug output' do
          before(:each) do
            allow(Chef::Log).to receive(:debug).and_call_original
          end

          it 'indicates an active lock' do
            expect(Chef::Log).to receive(:debug).with('Found an active reboot lock')
          end

          after(:each) do
            @rl.exists?
          end
        end

        it 'returns true' do
          expect(@rl.exists?).to eq(true)
        end
      end
    end
  end

  describe '#set' do
    context 'when a lock exists' do
      before(:each) do
        expect(@zk_client).to receive(:exists?).with("#{@base_node}/lock").and_return(true)
      end

      context 'and it was created by this client' do
        before(:each) do
          allow(@rl).to receive(:lock).and_return([@my_node_fqdn])
        end

        describe 'prints debug output' do
          it 'about deleting reboot lock' do
            allow(Chef::Log).to receive(:debug).and_call_original
            allow(@zk_client).to receive(:create)
            allow(@zk_client).to receive(:delete)
            expect(Chef::Log).to receive(:debug).with('Deleting reboot lock')
            @rl.set
          end
        end

        context 'and it is not expired' do
          before(:each) do
            allow(@rl).to receive(:expired?).and_return(false)
          end

          describe 'print debug output' do
            before(:each) do
              allow(Chef::Log).to receive(:debug).and_call_original
              allow(@zk_client).to receive(:create)
              allow(@zk_client).to receive(:delete)
            end

            it 'about deleting locks' do
              expect(Chef::Log).to receive(:debug).with('Deleting reboot lock')
            end
          end

          it 'deletes the old lock' do
            expect(@zk_client).to receive(:delete).with("#{@base_node}/lock")
            allow(@zk_client).to receive(:create)
          end

          after(:each) do
            @rl.set
          end
        end
      end

      context 'and it was created by another client' do
        before(:each) do
          allow(@rl).to receive(:lock).and_return(['some_other_fqdn'])
        end

        context 'and it is not expired' do
          before(:each) do
            allow(@rl).to receive(:expired?).and_return(false)
          end

          it 'throws an exception' do
            expect { @rl.set }.to raise_exception(
              RuntimeError,
              'Tried to create a lock when a fresh one already exists'
            )
          end
        end

        context 'and it is expired' do
          before(:each) do
            allow(@rl).to receive(:expired?).and_return(true)
            allow(@zk_client).to receive(:delete)
            allow(@zk_client).to receive(:create)
          end

          it 'does not throw an exception' do
            expect { @rl.set }.to_not raise_exception
          end
        end
      end
    end

    context 'when a lock does not exist' do
      before(:each) do
        allow(@zk_client).to receive(:exists?).and_return(false)
      end

      describe 'prints debug output' do
        it 'about creating a reboot lock' do
          allow(Chef::Log).to receive(:debug).and_call_original
          allow(@zk_client).to receive(:create)
          expect(Chef::Log).to receive(:debug).with('Creating a new reboot lock')
        end
      end

      it 'creates a lock' do
        expect(@zk_client).to receive(:create).with(
          "#{@base_node}/lock",
          @my_node_fqdn,
          or: :set
        )
      end

      after(:each) do
        @rl.set
      end
    end
  end

  describe '#expired?' do
    context 'the lock is old' do
      before(:each) do
        lock_stats = object_double(
          'lock_stats',
          ctime: ((Time.now.to_i - @reboot_interval - 1) * 1000)
        )
        allow(@rl).to receive(:lock).and_return([nil, lock_stats])
      end

      describe 'print debug output' do
        it 'describes the lock age' do
          expect(Chef::Log).to receive(:debug).with(
            "Reboot lock age: #{@reboot_interval + 1} (interval is #{@reboot_interval})"
          )
          @rl.expired?
        end
      end

      it 'returns true' do
        expect(@rl.expired?).to eq(true)
      end
    end

    context 'the lock is recent' do
      before(:each) do
        lock_stats = object_double(
          'lock_stats',
          ctime: ((Time.now.to_i - 1) * 1000)
        )
        allow(@rl).to receive(:lock).and_return([nil, lock_stats])
      end

      describe 'print debug output' do
        it 'describes the lock age' do
          expect(Chef::Log).to receive(:debug).with(
            "Reboot lock age: 1 (interval is #{@reboot_interval})"
          )
          @rl.expired?
        end
      end

      it 'returns false' do
        expect(@rl.expired?).to eq(false)
      end
    end
  end

  describe '#lock' do
    it 'gets the lock from Zookeeper' do
      expect(@zk_client).to receive(:get).with("#{@base_node}/lock")
      @rl.lock
    end
  end
end
