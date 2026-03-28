# ColosseumCTF

## Settings
The configuration file (configs.json) is divided in 3 sections:
- ad-platform
- incus-cluster

### Colosseum section
The ad-platform section has two config that must be specified:
- teams: list. It's a list of the team's names that will partecipate to the competion.
- subnet_ip: dict. It's a dictionary containing that must contain the following keys:
    * gameserver-network
    * vulnboxes-network
    * vpn-servers-network

Every key must be associated with a correct subnet (e.g. 10.0.12.0/24)

### incus-cluster section
The incus cluster section has the following keys:
- nodes: dict. 
- project: string. Name of the incus project
- instances_type: string. Type of the incus instance. It must be container or virtual-machine
- player_number: int. Number of players for team.
- remote: string. Incus remote
