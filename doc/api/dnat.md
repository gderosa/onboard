# **Margay's iptables/DNAT API v1**

JSON API to manage DNAT in a Margay system.

# *Preliminary info*

## Authentication

Unless otherwise noted, use [Basic HTTP Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
at each request. The default user is `admin`, password `admin`. Of course, the administrator
is advised to change this in production.

For example, with [cURL](https://curl.haxx.se/), use `curl -u <username>:<password> <URL>`
&mdash; or `curl -u <username> <URL>` and enter the password when prompted.

# *DNAT*

## Create rule
```
PUT /api/v1/network/nat/dnat
```

Body:
```javascript
{
  "add_rule": true,
  "append_insert": "-I",
  "chain": "PREROUTING",
  "input_iface": "eth0",
  "proto": "tcp",
  "dest_addr": "1.2.3.0/20",
  "dest_ports": "123:456",
  "comment": "ciao",
  "source_addr": "5.6.7.0/24",
  "source_ports": "666:777",
  "mac_source": "aa:bb:cc:dd:ee:12",
  "jump-target": "DNAT",
  "to-destination_addr": "9.8.7.6",
  "to-destination_port": "54321"
}
```

### Info on some body properties:

* `"append_insert"`: "-I" to insert on top, "-A" to append at the bottom of the list of rules
* `"chain"`: always "PREROUTING"
* `"jump-target"`: "DNAT" (recommended); "REDIRECT" (transparent proxy); "ACCEPT" (do nothing)


## List rules
```
GET /api/v1/network/nat/dnat
```

```javascript
{
    "nat": {
        "name": "nat",
        "chains": {
            "PREROUTING": {
                "name": "PREROUTING",
                "listfields": [
                    "#",
                    "pkts",
                    "bytes",
                    "target",
                    "prot",
                    "opt",
                    "in",
                    "out",
                    "source",
                    "destination",
                    "misc"
                ],
                "rules": [
                    [
                        1,
                        "0",
                        "0",
                        "DNAT",
                        "tcp",
                        "--",
                        "eth0",
                        "*",
                        "0.0.0.0/0",
                        "1.2.0.0/20",
                        "tcp spts:666:777 dpts:123:456 MAC AA:BB:CC:DD:EE:12 /* ciao2 */ to:9.8.7.6:54321"
                    ],
                    [
                        2,
                        "0",
                        "0",
                        "DNAT",
                        "tcp",
                        "--",
                        "eth0",
                        "*",
                        "5.6.7.0/24",
                        "1.2.0.0/20",
                        "tcp spts:666:777 dpts:123:456 MAC AA:BB:CC:DD:EE:12 /* ciao */ to:9.8.7.6:54321"
                    ]
                ],
                "rulespecs": [
                    "-d 1.2.0.0/20 -i eth0 -p tcp -m tcp --sport 666:777 --dport 123:456 -m mac --mac-source AA:BB:CC:DD:EE:12 -m comment --comment ciao2 -j DNAT --to-destination 9.8.7.6:54321",
                    "-s 5.6.7.0/24 -d 1.2.0.0/20 -i eth0 -p tcp -m tcp --sport 666:777 --dport 123:456 -m mac --mac-source AA:BB:CC:DD:EE:12 -m comment --comment ciao -j DNAT --to-destination 9.8.7.6:54321"
                ]
            },
            "INPUT": {
                "name": "INPUT",
                "listfields": [
                    "#",
                    "pkts",
                    "bytes",
                    "target",
                    "prot",
                    "opt",
                    "in",
                    "out",
                    "source",
                    "destination",
                    "misc"
                ],
                "rules": [],
                "rulespecs": []
            },
            "POSTROUTING": {
                "name": "POSTROUTING",
                "listfields": [
                    "#",
                    "pkts",
                    "bytes",
                    "target",
                    "prot",
                    "opt",
                    "in",
                    "out",
                    "source",
                    "destination",
                    "misc"
                ],
                "rules": [],
                "rulespecs": []
            },
            "OUTPUT": {
                "name": "OUTPUT",
                "listfields": [
                    "#",
                    "pkts",
                    "bytes",
                    "target",
                    "prot",
                    "opt",
                    "in",
                    "out",
                    "source",
                    "destination",
                    "misc"
                ],
                "rules": [],
                "rulespecs": []
            }
        }
    }
}
```

Only the PREROUTING chain is relevant for DNAT.

## Delete a rule
```
PUT /api/v1/network/nat/dnat
```

### Body
```javascript
{
  "chain": "PREROUTING",
  "rulenum": "2",
  "del_rule": true
}
```

Refers to the list of rules [above](#list-rules). Rules are numbered starting from 1.

## Move a rule up/down
```
PUT /api/v1/network/nat/dnat
```

### Body
Move up:
```javascript
{
  "chain": "PREROUTING",
  "rulenum": "2",
  "move_rule_up": true
}
```
Move down:
```javascript
{
  "chain": "PREROUTING",
  "rulenum": "2",
  "move_rule_down": true
}
```

`rulenum` is the rule order number (which can be inferred after a GET request, see [above](#list-rules)).
Rules are numbered starting from 1.
