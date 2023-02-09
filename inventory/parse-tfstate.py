#!/usr/bin/env python3

# [-] References
# 1. arg_parser code taken from --> https://www.redhat.com/sysadmin/ansible-dynamic-inventory-python


import os
import argparse
import sys
import json
from contextlib import suppress

def get_empty_vars():
    return json.dumps({})


def generator():
    #sets pwd to the absolute path that the .py file is executed from
    pwd = os.path.realpath(os.path.dirname(__file__))

    #sets tf_path to a string that is the absolute path for the tfstate file
    tf_path = f"{pwd}/../tf/terraform.tfstate"

    #assertion ensures that the path to the state file exists; otherwise raise an error
    assert os.path.exists(tf_path), "Could not find terraform state"

    #opens the .tfstate file and returns it as a json object
    with open(tf_path, 'r') as f, suppress(AssertionError):
        tfstate = json.load(f)
        r = "resources"
        
        #Ensures that there is a "resource" block within the .tfstate file
        assert r in tfstate.keys() and len(tfstate[r]) > 0

        
        vm = next(filter(lambda i: i["type"] == "aws_instance", tfstate[r]), None)
        assert vm is not None and len(vm["instances"]) == 1
        vm_name = vm["name"].replace("-", "_")
        vm_attrs = vm["instances"][0]["attributes"]

        out = {
            "all": {
                "children": ["aws_hosts"]
            },
            "aws_hosts": {
                "hosts": [vm_name]
            },
            "_meta": {
                "hostvars": {
                    vm_name: {
                        "ansible_host": vm_attrs["public_ip"],
                        "ansible_user": "ubuntu",
                        "ansible_ssh_private_key_file": "~/.ssh/bbotTraining"
                    }
                }
            }
        }

        print(json.dumps(out, indent=True))

    return 0

if __name__ == "__main__":

    arg_parser = argparse.ArgumentParser(
        description=__doc__,
        prog=__file__
    )
    arg_parser.add_argument(
        '--pretty',
        action='store_true',
        default=False,
        help="Pretty print JSON"
    )
    mandatory_options = arg_parser.add_mutually_exclusive_group()
    mandatory_options.add_argument(
        '--list',
        action='store',
        nargs="*",
        default="dummy",
        help="Show JSON of all managed hosts"
    )
    mandatory_options.add_argument(
        '--host',
        action='store',
        help="Display vars related to the host"
    )

    try:
        args = arg_parser.parse_args()
        if args.host:
            print(get_empty_vars())
        elif len(args.list) >= 0:
            generator()
        else:
            raise ValueError("Expecting either --host $HOSTNAME or --list")

    except ValueError:
        raise

