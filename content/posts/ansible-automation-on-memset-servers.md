---
title: "Ansible Automation on Memset Servers"
date: 2017-01-26T12:00:00+00:00
draft: false
tags: ["ansible", "memset", "orchestration"]
---

### What is Ansible?

> Ansible is an open source automation tool, which facilitates configuration management, application deployment and task automation.

A complex multi-step process can be automated and run with a simple command from your workstation: `ansible-playbook task.yml`.

A key word for Ansible is '*ensure*'. Ansible will work to ensure that configuration / tasks are run. If a task completes without changing any settings, it is 'ok'. Otherwise, it was 'changed' or sometimes 'failed' ([*which is not always a Bad Thing™*](https://docs.ansible.com/ansible/playbooks_conditionals.html#the-when-statement))

Ansible is best compared to one of the 'greats' of automation and configuration management: Puppet.

While Puppet is ideal for ensuring that configuration is static and unchanging, it requires a great deal of setup and infrastructure: a puppetmaster server must be configured and available at all times, and all clients must be configured with the agent which periodically pulls the configuration.

Ansible, however, requires only a workstation with Python 2.6 / 2.7 and the [Ansible CLI package](https://docs.ansible.com/ansible/intro_getting_started.html). All communication is performed over SSH (it is assumed that the servers are accessible over ssh). Configuration and tasks are pushed to the servers on-demand, and results are fed back to the controller in real-time.

### The Ansible Inventory

A key part of Ansible is the inventory: a static file which describes all the hosts you wish to control.

This is located at `/etc/ansible/hosts` by default.

The following is an example of a simple inventory:

{{< highlight ini >}}
[web]
testyaa46.miniserver.com
testyaa61.miniserver.com

[mariadb]
testyaa21.miniserver.com
testyaa49.miniserver.com
{{< /highlight >}}

This defines two groups of servers: web and mariadb.

Ansible automatically collects information about the servers on each run, which it will load into your inventory as variables. However, it can be useful to add your own information to each server. This is possible with [custom variables](https://docs.ansible.com/ansible/playbooks_variables.html).

Custom variables can be assigned to individual hosts in the inventory:

{{< highlight ini >}}
[web]
testyaa46.miniserver.com ansible_ssh_user=tom nickname=webhost1
{{< /highlight >}}

Or to groups:
{{< highlight ini >}}
[web:vars]
ansible_ssh_user=tom
http_port=80
{{< /highlight >}}

Ansible provide [detailed documentation](https://docs.ansible.com/ansible/intro_inventory.html) on the inventory file.

#### Inventory gotchas:

The management of the inventory file can become a job in itself, though, as all servers need to be added and classified.

For specific-use machines (web / database servers) this is sensible, as you do not necessarily want to make assumptions about those kind of servers. However, for general maintenance it is useful to have all the servers under your control available within the inventory. To simplify this, the best approach is...

### Automatically building the inventory

Ansible allows an executable script to be used in place of the static hosts file, which will populate the Ansible inventory from a given data source

I have written a script to integrate Ansible with the [Memset API](https://www.memset.com/apidocs/).

[This is available on Github](https://github.com/Memset/memset-ansible-dynamic-inventory)

This script will generate 4 groups within Ansible:

- [memset-linux]
- [memset-windows]
- [memset-dunsfold]
- [memset-reading]

These groups will be populated with the servers on your Memset account.

Additionally, a number of variables containing information about your servers are provided to Ansible from the API, which are [documented here](https://github.com/Memset/memset-ansible-dynamic-inventory/blob/master/Docs/Variables.md).

Documentation on how to install and use this script is available in the project's [readme](https://github.com/Memset/memset-ansible-dynamic-inventory/blob/master/README.md).

#### Testing the inventory

A simple test that this script is working for you would be with Ansible's ping module:

This will ping all the linux servers on your Memset Account:

```
ansible memset-linux -m ping
```

Further filtering can be performed using the other groups - this will ping all the linux servers in the Dunsfold network zone:

```
ansible memset-linux -l memset-dunsfold -m ping
```

### Ansible Playbooks

Playbooks are, at their simplest form, a list of commands and modules. They are written in the YAML syntax, and a Playbook is tied to a specific group of servers.

Ansible's playbook documentation is here: https://docs.ansible.com/ansible/playbooks.html

Propagation and maintenance of SSH authorized_keys on multiple Linux servers, is a task which requires accuracy and reliability.

A common method for this would be:
1. Log into the server
2. View the ~/.ssh/authorized_keys file
3. Add any missing keys
4. Remove any unnecessary keys
5. Log out

With ansible, this can be done with the following Playbook:
{{< highlight yaml >}}
---
- hosts: memset-linux
  tasks:
    - name: "Ensure all required keys are allowed"
      authorized_key:
        user: "{{ ansible_ssh_user }}"
        state: present
        key: "{{ item }}"
      with_fileglob:
        - "/path/to/authorized/*"
    - name: "Ensure no disallowed keys are allowed"
      authorized_key:
        user: "{{ ansible_ssh_user }}"
        state: absent
        key: "{{ item }}"
      with_fileglob:
        - "/path/to/unauthorized/*"
{{< /highlight >}}
Where:
- `/path/to/authorized/` = a directory of public keys you want on the server
- `/path/to/unauthorized/` = a directory of public keys you DO NOT want on the server

<br />
Another possible use is updating the Message of the Day on the server with some information about the server from your Memset account, using the variables the [script](https://github.com/Memset/memset-ansible-dynamic-inventory) provides:

{{< highlight yaml >}}
---
- hosts: memset-linux
  tasks:
    - name: "Ensure motd matches the memset nickname"
      template:
        src: motd.j2
        dest: "/etc/motd"
        backup: no
      when: memset_nickname is defined
{{< /highlight >}}
Content of motd.j2:
{{< highlight twig >}}
{% if memset_nickname != '' %}Description: {{ memset_nickname }}{% endif %}

{% if memset_data_zone != '' %}Datacenter: {{ memset_network_zone }}{% endif %}

{% if memset_firewall_rule_group_nickname != '' %}Firewall Group: {{ memset_firewall_rule_group_nickname }}{% endif %}</pre>
{{< /highlight >}}
This would result in the motd reading, for example:

```
Description: Webhost 1
Datacenter: dunsfold
Firewall Group: Webhost Firewall
```

Comprehensive documentation on all of Ansible’s features is available [on their website](https://docs.ansible.com/ansible/).

*This article was also posted on the Memset Official Blog, [here](https://www.memset.com/blog/ansible-automation-with-memset).*
