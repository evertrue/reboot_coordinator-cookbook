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

  context 'When all attributes are default and the /var/run/reboot-required ' \
          'file exists' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new do |node|
        node.set['ec2']['placement_availability_zone'] = 'us-east-1d'
        node.set['reboot_coordinator']['acceptable_reboot_times'] = [Time.now.hour]
        allow_any_instance_of(File).to receive(:exist?).with('/var/run/reboot-required').and_return(true)
      end.converge(described_recipe)
    end

    it 'requests a reboot' do
      expect(chef_run).to request_reboot('catchall_reboot_handler')
    end
  end
end
