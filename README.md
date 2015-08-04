# reboot_coordinator

A cookbook that should help ensure that no two nodes in the same cluster (with the same value for `node['reboot_coordinator']['zk_base_node']`) are rebooted at the same time.

# Requirements

* ec2 - For basic usage
* Zookeeper - To use coordinated, sequenced reboots

# Usage

To ensure that reboots happen automatically (whenever '/var/run/reboot-required' exists and the scheduling requirements are met), simply include this recipe in a recipe or run list

Most of the code in this cookbook pertains to preventing unwanted reboots.

# Attributes

All attributes are in the `reboot_coordinator` namespace

- `reboot_permitted` - (Type: Boolean) The master switch. If this attribute is set to false, reboots will not happen. Defaults to **true**.
- `zk_base_node` - (Type: String) The Zookeeper node with which reboots should be coordinated. Set this if you want the cookbook to try to ensure that no two nodes in a cluster are rebooted at the same time. This is typically going to be unique per-cluster.
- `zk_hosts` - (Type: Array) A list of Zoopeeper hosts in the form: `['host1:2181', 'host2:2181']`
- `acceptable_reboot_times` - (Type: Range) A range of hours during which reboots are permitted. The default value is based on `['ec2']['placement_availability_zone']` like so:

AZ         | Range
---------- | -----
us-east-1a | 0 - 4
us-east-1b | 6 - 10
us-east-1c | 12 - 16
us-east-1d | 18 - 22

- `reboot_delay` - (Type: Integer) The delay (in minutes) passed to the shutdown command to warn people in advance that a shutdown will occur (defaults to 1 minute).
- `reboot_interval` - (Type: Integer) The spacing (in seconds) between reboots in a cluster when Zookeeper is in use (defaults to 5 minutes).

License & Authors
-----------------
* Author:: Eric Herot [eric.herot@evertrue.com](mailto:eric.herot@evertrue.com)

```text
Copyright:: 2015, EverTrue, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
