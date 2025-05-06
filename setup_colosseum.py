#!/usr/bin/env python
import ipaddress

import ansible_runner


def parse_colosseum_configs():
    with open("colosseum_configs.yaml", 'r', encoding='UTF-8') as f:
        pass
        # configs = json.load(f)

        # variables = {}

        # variables["teams"] = configs["ad_platform"]["teams"]
        # variables["player_number"] = configs["ad_platform"]["player_number"]

        # if not isinstance(variables["player_number"], int) or variables["player_number"] < 2:
        #     raise ValueError("The value of 'player_number' must be an integer greater then 1")
        # variables["public_ip"] = configs["ad_platform"]["public_ip"]

        # try:
        #     ipaddress.ip_address(variables["public_ip"])
        # except ValueError as e:
        #     raise ValueError("The value of public_ip must be a valid IPv4 address") from e

        # variables["nodes"] = configs["incus_cluster"]["nodes"]

        # if len(variables["nodes"]) == 2:
        #     raise ValueError("Can't have a number of nodes equal to 2")

        # for n in variables["nodes"].values():
        #     try:
        #         ipaddress.ip_address(n)
        #     except ValueError as e:
        #         raise ValueError("The value of 'nodes' must be a list of valid IPv4 address") from e

        # variables["remote"] = configs["incus_cluster"]["remote"]

        # variables["networks"] = configs["ad_platform"]["networks"]

        # try:
        #     ipaddress.ip_network(variables["networks"]["gameserver-network"], False)
        #     ipaddress.ip_network(variables["networks"]["vulnboxes-network"], False)
        #     ipaddress.ip_network(variables["networks"]["vpn-servers-network"], False)
        # except ValueError as e:
        #     raise ValueError("The value of each network must be a valid address in CIDR notation") from e

        # variables["ansible_user"] = configs["incus_cluster"]["ansible_user"]

        # variables["instances_type"] = configs["incus_cluster"]["instances_type"]

        # if variables["instances_type"] != "virtual-machine" and variables["instances_type"] != "container":
        #     raise ValueError("The value of 'instance_type' must be 'virtual-machine' or 'container'")

        # return variables


def generate_inventory(variables):
    vulnboxes = ["nop-vulnbox"]
    vpns = []
    cluster_nodes = []
    nodes_names = dict()

    for n in variables["nodes"].keys():
        cluster_nodes.append(variables["nodes"][n])
        nodes_names[variables["nodes"][n]] = n

    cluster_address = cluster_nodes[0]

    if len(variables["nodes"]) == 1:
        inventory_cluster = {
            "cluster_nodes": {
                "hosts": cluster_nodes,
                "vars": {
                    "server_1": cluster_nodes[0],
                    "remote": variables["remote"],
                    "ansible_connection": "ssh",
                    "networks": variables["networks"],
                    "ansible_user": variables["ansible_user"]
                }
            }
        }

    else:
        inventory_cluster = {
            "cluster_nodes": {
                "hosts": cluster_nodes,
                "vars": {
                    "nodes_names": nodes_names,
                    "remote": variables["remote"],
                    "server_1": cluster_nodes[0],
                    "server_2": cluster_nodes[1],
                    "server_3": cluster_nodes[2],
                    "networks": variables["networks"],
                    "ansible_connection": "ssh",
                    "ansible_user": variables["ansible_user"]
                }
            }
        }

    for t in variables["teams"]:
        vulnboxes.append(t + "-vulnbox")
        vpns.append(t + "-vpn")

    ip_pattern = variables["networks"]["vulnboxes-network"].split(".")
    ip_pattern[2] = "%"
    ip_pattern[3] = "1"
    ip_pattern = ".".join(ip_pattern)

    inventory = {
        "faustgameserver": {
            "hosts": ["gameserver"],
            "vars": {
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
                "ctf_gameserver_web_allowed_hosts": ["{{ ansible_fqdn }}", variables["player_number"]],
                "ansible_connection": "community.general.incus",
                "ansible_incus_remote": variables["remote"]
            }
        },
        "vulnboxes": {
            "hosts": vulnboxes,
            "vars": {
                "ansible_connection": "community.general.incus",
                "ansible_incus_remote": variables["remote"]
            }
        },

        "vpns": {
            "hosts": vpns,
            "vars": {
                "endpoint_address": variables["public_ip"],
                "vpn_players": variables["player_number"],
                "ansible_connection": "community.general.incus",
                "ansible_incus_remote": variables["remote"],
            }
        },
        "all": {
            "vars": {
                "cluster_address": cluster_address,
                "instances_type": variables["instances_type"],
                "networks": variables["networks"],
                "remote": variables["remote"],
                "teams": variables["teams"],
                "ansible_connection": "local"
            }
        }
    }

    inventory.update(inventory_cluster)
    print(json.dumps(inventory, indent=2))


if __name__ == '__main__':
    variables = parse_colosseum_configs()
