#!/bin/bash

############################################################
#                                                          #
#                                                          #
#    [-] ASM - BBOT Training Infrastructure                #
#                                                          #
#    [-] 2022.02.08                                        #
#          V04                                             #
#          Black Lantern Security (BLSOPS)                 #
#                                                          #
#                                                          #
############################################################

#Assumptions
	# Ubuntu 22.04 LTS Desktop is the base OS for this workstation
	# An AWS tenant is available
	# This workstation has internet access
	# AWS Access Key ID and Secret Key are configured and known
	# BLSOPS is providing a public GitHub repository with ALL Ansible playbooks and files

#Purpose
	# Local installs for:
		# pip
		# Ansible
		# BLSOPS GitHub repository
        # Reads-in AWS credentials
	# Executes Ansible Playbook:
		# Creates Public/Private key pair 
		# Installs Terraform
		# Calls Terraform, instantiates EC2 instance (Free Tier), installs certificate
		# Remote EC2 installs for:
			# BBOT and dependencies
			# Docker
			# Neo4J
	# Outputs commands for BBOT and NEO4J access
	# Outputs command for Terraform Destroy

# Turn on debug and set environment
set -euo pipefail
export PATH=${PATH}:~/.local/bin/
export ANSIBLE_HOST_KEY_CHECKING=True
export ANSIBLE_SSH_PIPELINING=True
export ANSIBLE_GATHERING=smart

# ============ PIP INSTALL ============

PIP_R=https://bootstrap.pypa.io/get-pip.py
PIP_L=/tmp/get-pip.py
wget -q ${PIP_R} -O ${PIP_L}
/usr/bin/python3 ${PIP_L} --user

# ============ ANSIBLE INSTALL ============

pip install ansible

# ============ BLSOPS ANSIBLE REPOSITORY ============

ANS_R="https://github.com/blacklanternsecurity/ASM_BBOT_Training/archive/refs/heads/master.tar.gz"
ANS_L=~/ASM_BBOT_Training-master

mkdir -p "${ANS_L}"
wget -qO- "${ANS_R}" | tar xzC ~

# ============ READ AWS CREDENTIALS ============

set +u
if [ -z "${AWS_ACCESS_KEY_ID}" -o -z "${AWS_SECRET_ACCESS_KEY}" ]; then
    unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
    read -p "AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
    export AWS_ACCESS_KEY_ID

    read -s -p "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
    export AWS_SECRET_ACCESS_KEY
fi
set -u

# ============ ANSIBLE PLAYBOOK ============

ansible-playbook -i "${ANS_L}/inventory" "${ANS_L}/bbot_setup.yml"
