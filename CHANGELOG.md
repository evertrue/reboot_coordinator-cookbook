reboot_coordinator CHANGELOG
======================
This is the Changelog for the reboot_coordinator cookbook.

v2.0.0 (2016-09-16)
-------------------

* New feature: Pre-reboot commands
* Default to 5 minute reboots with 1 minute during testing
* **BREAKING:** Update ohai config for Ohai v4

v1.0.3 (2016-02-23)
-------------------

* Move ohai plugin to its own recipe

v1.0.2 (2015-08-11)
-------------------

* Output zookeeper hosts in debug log

v1.0.1 (2015-08-06)
-------------------

* Use an ohai plugin to assess the presence of /var/run/reboot-required

v1.0.0 (2015-08-05)
-------------------

* First release!
