#!/bin/bash
cd /root/ansible
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook playbooks/main.yml -e profile=work -e ansible_user=vagrant -e ansible_password=vagrant -e packval=false -v
