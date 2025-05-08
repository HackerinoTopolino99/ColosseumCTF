#!/usr/bin/env python3
import os
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


def build_packer_templates(remote: "str") -> None:

    init_command = ["packer", "init", "packer/templates"]
    build_command = ['packer', 'build', '-var', f'"remote={remote}"']
    execute(init_command)
    execute(build_command)

def parse_colosseum_configs():
    with open("colosseum_configs.yaml", 'r', encoding='UTF-8') as f:
        configurations = yaml.safe_load(f)

        colosseum_configs = configurations["colosseum"]
        cluster_configs = configurations["cluster"]

        if len(cluster_configs["nodes"]) == 2:
            raise ValueError("Error: The number of nodes must not be 2")

        if colosseum_configs["instances_type"] != "container" and colosseum_configs["instances_type"] != "virtual-machine":
            raise ValueError("Error: The value of 'instance_type' must be 'virtual-machine' or 'container'")

        for _ in cluster_configs["nodes"]:
            if not valid_ipv4_address(cluster_configs["nodes"][_]):
                raise ValueError(f"Error: The value of {cluster_configs["nodes"][_]} must be a valid IPv4 address")

        for _ in colosseum_configs["networks"]:
            if not valid_ipv4_network(colosseum_configs["networks"][_]):
                raise ValueError(f"Error: The value of {colosseum_configs["networks"][_]} must be a valid IPv4 network")

        if not isinstance(colosseum_configs["player_number"], int) or colosseum_configs["player_number"] < 2:
            raise ValueError("The value of 'player_number' must be an integer greater then 1")

        return colosseum_configs, cluster_configs


def setup_incus(settings: dict) -> None:
    cluster_nodes = []
    nodes_name = "\n"

    for n in settings["nodes"].keys():
        cluster_nodes.append(settings['nodes'][n])
        nodes_name += f"      {settings['nodes'][n]}: {n}\n"

    if len(settings["nodes"]) == 1:
        inventory = f"""cluster_nodes:
  hosts: {'      :\n'.join(cluster_nodes)}      :
  vars:
    server_1: {cluster_nodes[0]}
    cluster_address: {cluster_nodes[0]}
    remote: {settings["remote"]}
    ansible_connection: ssh
    ansible_user: {settings["ansible_user"]},
    ansible_python_interpreter: python3
"""

    else:
        inventory = f"""cluster_nodes:
  hosts:
    {':\n    '.join(cluster_nodes)}:
  vars:
    cluster_address: {cluster_nodes[0]}
    nodes_names: {nodes_name}
    server_1: {cluster_nodes[0]}
    server_2: {cluster_nodes[1]}
    server_3: {cluster_nodes[2]}
    remote: {settings["remote"]}
    ansible_connection: ssh
    ansible_user: {settings["ansible_user"]},
    ansible_python_interpreter: python3
"""

    runner = ansible_runner.run(
            private_data_dir="./ansible",
            playbook="setup_incus.yaml",
            inventory=inventory
            )

    if runner.rc != 0:
        raise RuntimeError(f"The playbook setup_incus.yaml failed with error {runner.rc}")


def deploy_colosseum(settings: dict) -> None:
    vulnboxes = []
    vpns = []

    for t in settings["teams"]:
        vulnboxes.append(t + "-vulnbox")
        vpns.append(t + "-vpn")

    ip_pattern = settings["networks"]["vulnboxes-network"].split(".")
    ip_pattern[2] = "%"
    ip_pattern[3] = "1"
    ip_pattern = ".".join(ip_pattern)

    inventory = {
        "faustgameserver": {
            "hosts": ["gameserver"],
            "settings": {
                "ctf_gameserver_db_pass_web": "password",
                "ctf_gameserver_db_pass_controller": "password",
                "ctf_gameserver_db_pass_submission": "password",
                "ctf_gameserver_db_pass_checker": "password",
                "ctf_gameserver_db_pass_vpnstatus": "password",
                "ctf_gameserver_web_admin_email": "admin@example.org",
                "ctf_gameserver_web_admin_pass": "admin",
                "ctf_gameserver_web_from_email": "sender@example.org",
                "ctf_gameserver_web_secret_key": "ZytYXi50TV9NSmtiQjlpTXh1WkNYKzI4fnQxXytYLzk=",
                "ctf_gameserver_web_timezone": "Europe/Rome",
                "ctf_gameserver_checker_ippattern": ip_pattern,
                "ctf_gameserver_flag_secret": "WHc5fF8jV2dnUnB5bS1mXS48KD1BfTdRLTtRYihAfFA=",
                "ctf_gameserver_submission_listen_host": "0.0.0.0",
                "ctf_gameserver_submission_listen_ports": [8080],
                "ctf_gameserver_db_user_vpnstatus": "gameserver_vpnstatus",
                "ctf_gameserver_web_allowed_hosts": ["{{ ansible_fqdn }}", settings["player_number"]],
                "ansible_connection": "community.general.incus",
                "ansible_incus_remote": settings["remote"]
            }
        },
        "vulnboxes": {
            "hosts": vulnboxes,
            "settings": {
                "ansible_connection": "community.general.incus",
                "ansible_incus_remote": settings["remote"]
            }
        },

        "vpns": {
            "hosts": vpns,
            "settings": {
                "endpoint_address": settings["public_ip"],
                "vpn_players": settings["player_number"],
                "ansible_connection": "community.general.incus",
                "ansible_incus_remote": settings["remote"],
            }
        },
        "all": {
            "settings": {
                "instances_type": settings["instances_type"],
                "networks": settings["networks"],
                "remote": settings["remote"],
                "teams": settings["teams"],
                "ansible_connection": "local"
            }
        }
    }

    print(yaml.dump(inventory))


if __name__ == '__main__':
    colosseum_configs, cluster_configs = parse_colosseum_configs()

    setup_incus(cluster_configs)
    build_packer_templates(colosseum_configs["remote"])
    #deploy_colosseum(colosseum_configs)
