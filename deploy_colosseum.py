#!/usr/bin/env python3
import argparse
import subprocess
import sys
from ipaddress import ip_address, IPv4Address, ip_network, IPv4Network

import ansible_runner
import yaml


def valid_ipv4_address(ip: str) -> bool:
    '''
    Check if a string is a valid IPv4 address
    '''
    try:
        if isinstance(ip_address(ip), IPv4Address):
            return True

        return False

    except ValueError:
        return False


def valid_ipv4_network(network: str) -> bool:
    '''
    Check if a string is a valid IPv4 address
    '''
    try:
        if isinstance(ip_network(network), IPv4Network):
            return True

        return False

    except ValueError:
        return False


def execute(cmd: list) -> None:
    # Source: https://stackoverflow.com/questions/4417546/constantly-print-subprocess-output-while-process-is-running
    print(f"[i] Executing the following command: {' '.join(cmd)}")

    try:
        with subprocess.Popen(cmd,
                              stdout=subprocess.PIPE,
                              universal_newlines=True,
                              text=True) as popen:

            for stdout_line in iter(popen.stdout.readline, ""):
                print(stdout_line, end="")

            popen.stdout.close()
            return_code = popen.wait()

            if return_code:
                raise subprocess.CalledProcessError(return_code, cmd)

    except subprocess.CalledProcessError:
        print("[!] Fatal Error!")
        print(f"[!] {' '.join(cmd)} failed")
        sys.exit(1)

    print(f"[i] Command {' '.join(cmd)} executed successfully!")


def build_packer_templates(remote: str, instance_type: str) -> None:
    if instance_type == "virtual-machine":
        virtual_machine = "true"
    else:
        virtual_machine = "false"

    init_command = ["packer", "init", "packer/templates"]
    build_command = ['packer', 'build', '-var', f'remote={remote}', '-var', f'virtual_machine={virtual_machine}', 'packer/templates']

    execute(init_command)
    execute(build_command)


def parse_colosseum_configurations():
    with open("colosseum_configs.yaml", 'r', encoding='UTF-8') as f:
        configurations = yaml.safe_load(f)

        if len(configurations["cluster"]["nodes"]) == 2:
            raise ValueError("Error: The number of nodes must not be 2")

        if configurations["colosseum"]["instances_type"] != "container" and configurations["colosseum"]["instances_type"] != "virtual-machine":
            raise ValueError("Error: The value of 'instance_type' must be 'virtual-machine' or 'container'")

        for _ in configurations["cluster"]["nodes"]:
            if not valid_ipv4_address(configurations["cluster"]["nodes"][_]):
                raise ValueError(f"Error: The value of {configurations["cluster"]["nodes"][_]} must be a valid IPv4 address")

        if not isinstance(configurations["colosseum"]["player_number"], int) or configurations["colosseum"]["player_number"] < 2:
            raise ValueError("The value of 'player_number' must be an integer greater then 1")

        return configurations["colosseum"], configurations["cluster"]


def setup_incus(settings: dict) -> None:
    cluster_nodes = {}
    nodes_name = {}

    for n in settings["nodes"].keys():
        cluster_nodes[settings['nodes'][n]] = None
        nodes_name[settings['nodes'][n]] = n

    if len(settings["nodes"]) == 1:
        inventory = {
            "cluster_nodes": {
                "hosts": cluster_nodes,
                "vars": {
                    "server_1": list(cluster_nodes.keys())[0],
                    "cluster_address": list(cluster_nodes.keys())[0],
                    "remote": settings["remote"],
                    "ansible_connection": "ssh",
                    "ansible_user": settings["ansible_user"],
                    "ansible_passowrd": settings["ansible_password"],
                    "ansible_become_pass": settings["ansible_password"],
                    "ansible_python_interpreter": "python3"
                }
            }
        }

        print(yaml.dump(inventory))
    else:
        inventory = {
            "cluster_nodes": {
                "hosts": cluster_nodes,
                "vars": {
                    "cluster_address": list(cluster_nodes.keys())[0],
                    "nodes_names": nodes_name,
                    "server_1": list(cluster_nodes.keys())[0],
                    "server_2": list(cluster_nodes.keys())[1],
                    "server_3": list(cluster_nodes.keys())[2],
                    "remote": settings["remote"],
                    "ansible_connection": "ssh",
                    "ansible_user": settings["ansible_user"],
                    "ansible_passowrd": settings["ansible_password"],
                    "ansible_become_pass": settings["ansible_password"],
                    "ansible_python_interpreter": "python3"
                }
            }
        }

    runner = ansible_runner.run(
            private_data_dir="./ansible",
            playbook="setup_incus.yaml",
            inventory=inventory
            )

    if runner.rc != 0:
        raise RuntimeError(f"The playbook setup_incus.yaml failed with error {runner.rc}")


def deploy_colosseum(settings: dict) -> None:
    vulnboxes = {}
    wireguard_servers = {}

    for t in settings["teams"]:
        vulnboxes[t + "-vulnbox"] = None
        wireguard_servers[t + "-vpn"] = None

    inventory = {
        "vulnboxes": {
            "hosts": vulnboxes,
        },

        "wireguard_servers": {
            "hosts": wireguard_servers,
            "vars": {
                "endpoint_address": settings["public_ip"],
                "vpn_players": settings["player_number"],
            }
        },
        "all": {
            "vars": {
                "cluster_address": settings["public_ip"],
                "ansible_connection": "community.general.incus",
                "ansible_incus_remote": settings["remote"],
                "instances_type": settings["instances_type"],
                "remote": settings["remote"],
                "teams": settings["teams"],
            }
        }
    }

    runner = ansible_runner.run(
            private_data_dir="./ansible",
            playbook="deploy_colosseum.yaml",
            inventory=yaml.dump(inventory)
            )

    if runner.rc != 0:
        raise RuntimeError(f"The playbook setup_incus.yaml failed with error {runner.rc}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--setup-incus",
                        action="store_true",
                        help="Boolean value for setup incus or not")

    args = parser.parse_args()

    colosseum_configs, cluster_configurations = parse_colosseum_configurations()

    if args.setup_incus:
        setup_incus(cluster_configurations)

#    build_packer_templates(colosseum_configs["remote"], colosseum_configs["instances_type"])
#    deploy_colosseum(colosseum_configs)
