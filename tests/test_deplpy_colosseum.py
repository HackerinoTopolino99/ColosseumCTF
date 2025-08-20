import sys
import os

from unittest import TestCase
from unittest.mock import patch, mock_open, MagicMock

sys.path.insert(0, os.path.abspath(
    os.path.join(os.path.dirname(__file__), "..")))
import deploy_colosseum


class TestDeployColosseum(TestCase):
    def test_valid_ipv4_address(self):
        self.assertTrue(deploy_colosseum.valid_ipv4_address("192.168.0.1"))
        self.assertFalse(deploy_colosseum.valid_ipv4_address("300.0.0.1"))
        self.assertFalse(deploy_colosseum.valid_ipv4_address("ciao"))

    def test_valid_ipv4_network(self):
        self.assertTrue(deploy_colosseum.valid_ipv4_network("192.168.0.0/24"))
        self.assertFalse(deploy_colosseum.valid_ipv4_network("192.168.0.0/33"))
        self.assertFalse(deploy_colosseum.valid_ipv4_network("abcd"))

    @patch("builtins.open", new_callable=mock_open, read_data="""
colosseum:
  instances_type: container
  player_number: 3
  remote: remote_host
  teams: [team1, team2]
cluster:
  nodes:
    node1: 192.168.0.10
    node2: 192.168.0.11
    node3: 192.168.0.12
""")
    def test_parse_colosseum_configurations_success(self, mock_file):
        colosseum, cluster = deploy_colosseum.parse_colosseum_configurations()
        self.assertEqual(colosseum["instances_type"], "container")
        self.assertEqual(cluster["nodes"]["node1"], "192.168.0.10")

    @patch("builtins.open", new_callable=mock_open, read_data="""
colosseum:
  instances_type: container
  player_number: 6
cluster:
  nodes:
    node1: invalid_ip
    node2: 192.168.0.11
""")
    def test_parse_colosseum_configurations_fail_two_nodes(self, mock_file):
        with self.assertRaises(ValueError) as cm:
            deploy_colosseum.parse_colosseum_configurations()

        self.assertEqual(str(cm.exception),
                         "Error: The number of nodes must not be 2")

    @patch("builtins.open", new_callable=mock_open, read_data="""
colosseum:
  instances_type: invalid_type
  player_number: 6
cluster:
  nodes:
    node1: 192.168.0.10
    node2: 192.168.0.11
    node3: 192.168.0.12
""")
    def test_parse_colosseum_configurations_fail_instance_type(self, mock_file):
        with self.assertRaises(ValueError) as cm:
            deploy_colosseum.parse_colosseum_configurations()

        self.assertEqual(str(cm.exception),
                         "Error: The value of 'instance_type' must be 'virtual-machine' or 'container'")

    @patch("builtins.open", new_callable=mock_open, read_data="""
colosseum:
  instances_type: container
  player_number: 6
cluster:
  nodes:
    node1: invalid_ip
    node2: 192.168.0.11
    node3: 192.168.0.12
""")
    def test_parse_colosseum_configurations_fail_invalid_ip(self, mock_file):
        with self.assertRaises(ValueError) as cm:
            deploy_colosseum.parse_colosseum_configurations()

        self.assertEqual(str(cm.exception),
                         "Error: The value of invalid_ip must be a valid IPv4 address")

    @patch("builtins.open", new_callable=mock_open, read_data="""
colosseum:
  instances_type: container
  player_number: 1
cluster:
  nodes:
    node1: 192.168.0.10
    node2: 192.168.0.11
    node3: 192.168.0.12
""")
    def test_parse_colosseum_configurations_fail_player_number_not_enough(self, mock_file):
        with self.assertRaises(ValueError) as cm:
            deploy_colosseum.parse_colosseum_configurations()

        self.assertEqual(str(cm.exception),
                         "The value of 'player_number' must be an integer greater then 1")

    @patch("builtins.open", new_callable=mock_open, read_data="""
colosseum:
  instances_type: container
  player_number: dsfgj
cluster:
  nodes:
    node1: 192.168.0.10
    node2: 192.168.0.11
    node3: 192.168.0.12
""")
    def test_parse_colosseum_configurations_fail_player_number_not_int(self, mock_file):
        with self.assertRaises(ValueError) as cm:
            deploy_colosseum.parse_colosseum_configurations()

        self.assertEqual(str(cm.exception),
                         "The value of 'player_number' must be an integer greater then 1")

#    @patch("deploy_colosseum.subprocess.Popen")
#    def test_execute_success(self, mock_popen):
#        mock_proc = MagicMock()
#        mock_proc.stdout.readline.return_value = ["output\n"]
#        mock_proc.wait.return_value = 0
#        mock_popen.return_value.__enter__.return_value = mock_proc
#        deploy_colosseum.execute(["echo", "hello"])
#        mock_popen.assert_called_once()
#
#    @patch("deploy_colosseum.subprocess.Popen")
#    @patch("sys.exit")
#    def test_execute_fail(self, mock_exit, mock_popen):
#        mock_proc = MagicMock()
#        mock_proc.stdout = ["error\n"]
#        mock_proc.wait.return_value = 1  # Return code != 0
#        mock_popen.return_value.__enter__.return_value = mock_proc
#        deploy_colosseum.execute(["false"])
#        mock_exit.assert_called_once_with(1)

    @patch("deploy_colosseum.ansible_runner.run")
    def test_setup_incus_success(self, mock_runner):
        mock_runner.return_value.rc = 0
        settings = {
            "nodes": {"node1": "192.168.0.10"},
            "remote": "remote_host",
            "ansible_user": "user",
            "ansible_password": "pass"
        }
        deploy_colosseum.setup_incus(settings)
        mock_runner.assert_called_once()

    @patch("deploy_colosseum.ansible_runner.run")
    def test_setup_incus_fail(self, mock_runner):
        mock_runner.return_value.rc = 1
        settings = {
            "nodes": {"node1": "192.168.0.10"},
            "remote": "remote_host",
            "ansible_user": "user",
            "ansible_password": "pass"
        }

        cluster_nodes = {}

        for n in settings["nodes"].keys():
            cluster_nodes[settings['nodes'][n]] = None

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
        with self.assertRaises(RuntimeError) as cm:
            deploy_colosseum.setup_incus(settings)

        mock_runner.assert_called_once_with(private_data_dir="./ansible",
                                            playbook="setup_incus.yaml",
                                            inventory=inventory)

        self.assertEqual(
            str(cm.exception),
            "The playbook setup_incus.yaml failed with error 1")

    @patch("deploy_colosseum.ansible_runner.run")
    def test_deploy_incus_success(self, mock_runner):
        mock_runner.return_value.rc = 0
        settings = {
            "nodes": {"node1": "192.168.0.10"},
            "remote": "remote_host",
            "ansible_user": "user",
            "ansible_password": "pass"
        }
        deploy_colosseum.setup_incus(settings)
        mock_runner.assert_called_once()

    @patch("deploy_colosseum.ansible_runner.run")
    def test_deploy_colosseum_fail(self, mock_runner):
        mock_runner.return_value.rc = 1
        settings = {
            "teams": ["team1", "team2"],
            "public_ip": "192.168.0.1",
            "player_number": 2,
            "instances_type": "container",
            "remote": "remote_host"
        }
        nodes_name = ["node1", "node2", "node3"]
        with self.assertRaises(RuntimeError) as cm:
            deploy_colosseum.deploy_colosseum(settings, nodes_name)

        self.assertEqual(
            str(cm.exception),
            "The playbook deploy_colosseum.yaml failed with error 1")
