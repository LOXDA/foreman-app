ansible-role-foreman-app
=========

Ansible role to deploy foreman app (or All-in-One) (theforeman.org)

Requirements
------------

It is designed to be include as a submodule to a project with its siblings :

* `ansible-role-foreman-db`
* `ansible-role-foreman-puppet`
* `ansible-role-foreman-proxy`
* `ansible-role-foreman-app` (this one)
* `ansible-role-foreman-custom`

`ansible-role-mirror` should help you get started with mirroring needed repositories.

Role Variables
--------------

The role needs some vars (default/main.yml)
The vars are self-explanatory, to look for answer one could use : foreman-installer --help
All vars are combined in `tasks/Setup_Options.yml` ( -vv is your friend )

Example Playbook
----------------

```
- hosts: tfm_app
  gather_facts: true
  roles:
    - role: foreman-app
```

```
# fetch oauth_consumer_* info
- hosts: "{{ groups['tfm_app'][0] }}"
  gather_facts: true
  tasks:
    - name: Fetch settings.yaml
      slurp:
        src: /etc/foreman/settings.yaml
      register: settingsyaml
    - name: Collect oauth_consumer_key
      set_fact:
        oauth_consumer_key: "{{ settingsyaml['content'] | b64decode | regex_findall(':oauth_consumer_key: (.+)') | first }}"
    - name: Collect oauth_consumer_secret
      set_fact:
        oauth_consumer_secret: "{{ settingsyaml['content'] | b64decode | regex_findall(':oauth_consumer_secret: (.+)') | first }}"
```

License
-------

CC-BY-4.0

Author Information
------------------

Thomas Basset -- hobbyist sysadm <tomm+code@loxda.net>
