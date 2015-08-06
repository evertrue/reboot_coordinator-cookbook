#
# Cookbook Name:: reboot_coordinator
# Spec:: default
#
# Copyright (c) 2015 The Authors, All Rights Reserved.

require 'spec_helper'

describe 'reboot_coordinator::default' do
  context 'When almost all attributes are default, on an unspecified platform' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new do |node|
        node.set['ec2']['placement_availability_zone'] = 'us-east-1d'
      end
      runner.converge(described_recipe)
    end

    # These are commented out because, for some reason, there is no
    # run_ruby_block method in the testing namespace...
    #
    # it 'does not clear any locks' do
    #   expect(chef_run).to_not run_ruby_bock('clear_reboot_lock')
    # end

    # it 'does not set any locks' do
    #   expect(chef_run).to_not run_ruby_bock('set_reboot_lock')
    # end

    it 'does not request a reboot' do
      expect(chef_run).to_not request_reboot('catchall_reboot_handler')
    end

    it 'converges successfully' do
      chef_run # This should not raise an error
    end
  end

  context 'When all attributes are default and pending_reboot is true' do
    context 'and zk_base_node is not set' do
      context 'and time is within acceptable_reboot_times' do
        context 'and reboot_permitted is true' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new do |node|
              node.set['ec2']['placement_availability_zone'] = 'us-east-1d'
              node.set['reboot_coordinator']['acceptable_reboot_times'] = [Time.now.hour]
              node.set['pending_reboot'] = true
            end.converge(described_recipe)
          end

          it 'requests a reboot' do
            expect(chef_run).to request_reboot('catchall_reboot_handler')
          end
        end

        context 'and reboot_permitted is false' do
          let(:chef_run) do
            ChefSpec::SoloRunner.new do |node|
              node.set['ec2']['placement_availability_zone'] = 'us-east-1d'
              node.set['reboot_coordinator']['acceptable_reboot_times'] = [Time.now.hour]
              node.set['reboot_coordinator']['reboot_permitted'] = false
              node.set['pending_reboot'] = true
            end.converge(described_recipe)
          end

          it 'does not request a reboot' do
            expect(chef_run).to_not request_reboot('catchall_reboot_handler')
          end
        end
      end

      context 'and time is outside of acceptable_reboot_times' do
        let(:chef_run) do
          ChefSpec::SoloRunner.new do |node|
            node.set['ec2']['placement_availability_zone'] = 'us-east-1d'
            node.set['reboot_coordinator']['acceptable_reboot_times'] = [0]
            node.set['pending_reboot'] = true
          end.converge(described_recipe)
        end

        it 'does not request a reboot' do
          expect(chef_run).to_not request_reboot('catchall_reboot_handler')
        end
      end
    end

    context 'and zk_base_node is set' do
      before do
        @zk_base_node = '/rspec_reboot_node'
      end

      context 'and no reboot lock exists' do
        let(:chef_run) do
          ChefSpec::SoloRunner.new do |node|
            rl = double('rl_double')
            allow(rl).to receive(:exists?).and_return(false)
            allow(RebootCoordinator::Helpers::RebootLock).to receive(:new).and_return(rl)

            node.set['ec2']['placement_availability_zone'] = 'us-east-1d'
            node.set['reboot_coordinator']['acceptable_reboot_times'] = [Time.now.hour]
            node.set['reboot_coordinator']['zk_base_node'] = @zk_base_node
            node.set['et_mesos_slave']['mocking'] = true
            node.set['pending_reboot'] = true
          end.converge(described_recipe)
        end

        it 'requests a reboot' do
          expect(chef_run).to request_reboot('catchall_reboot_handler')
        end
      end

      context 'and a reboot lock exists' do
        let(:chef_run) do
          ChefSpec::SoloRunner.new do |node|
            rl = double('rl_double')
            allow(rl).to receive(:exists?).and_return(true)
            allow(RebootCoordinator::Helpers::RebootLock).to receive(:new).and_return(rl)

            node.set['ec2']['placement_availability_zone'] = 'us-east-1d'
            node.set['reboot_coordinator']['acceptable_reboot_times'] = [Time.now.hour]
            node.set['reboot_coordinator']['zk_base_node'] = @zk_base_node
            node.set['et_mesos_slave']['mocking'] = true
            node.set['pending_reboot'] = true
          end.converge(described_recipe)
        end

        it 'does not request a reboot' do
          expect(chef_run).to_not request_reboot('catchall_reboot_handler')
        end
      end
    end
  end
end
