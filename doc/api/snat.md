# **Margay's iptables/SNAT API v1**

JSON API to manage SNAT in a Margay system.

# *Preliminary info*

## Authentication

Unless otherwise noted, use [Basic HTTP Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
at each request. The default user is `admin`, password `admin`. Of course, the administrator
is advised to change this in production.

For example, with [cURL](https://curl.haxx.se/), use `curl -u <username>:<password> <URL>`
&mdash; or `curl -u <username> <URL>` and enter the password when prompted.

# *SNAT*

## Create rule
```
PUT /api/v1/network/nat/snat
```

Body:
```javascript
{
  "add_rule": true,
  "append_insert": "-I",        // or "-A" to append the rule at bottom
  "chain": "POSTROUTING",
  "output_iface": "eth0",
  "proto": "tcp",
  "source_addr": "5.6.7.0/24",
  "source_ports": "666:777",
  "dest_addr": "1.2.3.0/20",
  "dest_ports": "123:456",      // range e.g. "123:456", or inidividual port e.g. "123"
  "comment": "ciao",
  "jump-target": "SNAT",        // or "MASQUERADE"
  "to-source_addr": "9.8.7.6",  // only with "jump-target": "SNAT"
  "to-source_port": "54321"     // only with "jump-target": "SNAT"
}
```

### Info on some body properties:

* `"append_insert"`: "-I" to insert on top, "-A" to append at the bottom of the list of rules
* `"chain"`: always "POSTROUTING"
* `"jump-target"`:
  * "MASQUERADE" (simpler);
  * "SNAT" (allows specifying address/port to translate into);
  * "ACCEPT" (do nothing)


## List rules
```
GET /api/v1/network/nat/snat
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
            "5.6.7.0/24",
            "1.2.0.0/20",
            "tcp spts:666:777 dpts:123:456 MAC AA:BB:CC:DD:EE:12 /* ciao */ to:9.8.7.6:54321"
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
          ],
          [
            3,
            "0",
            "0",
            "ACCEPT",
            "all",
            "--",
            "wlan0",
            "*",
            "0.0.0.0/0",
            "0.0.0.0/0",
            "--"
          ]
        ],
        "rulespecs": [
          "-s 5.6.7.0/24 -d 1.2.0.0/20 -i eth0 -p tcp -m tcp --sport 666:777 --dport 123:456 -m mac --mac-source AA:BB:CC:DD:EE:12 -m comment --comment ciao -j DNAT --to-destination 9.8.7.6:54321",
          "-s 5.6.7.0/24 -d 1.2.0.0/20 -i eth0 -p tcp -m tcp --sport 666:777 --dport 123:456 -m mac --mac-source AA:BB:CC:DD:EE:12 -m comment --comment ciao -j DNAT --to-destination 9.8.7.6:54321",
          "-i wlan0 -j ACCEPT"
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
        "rules": [

        ],
        "rulespecs": [

        ]
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
        "rules": [
          [
            1,
            "0",
            "0",
            "SNAT",
            "tcp",
            "--",
            "*",
            "eth0",
            "5.6.7.0/24",
            "1.2.0.0/20",
            "tcp spts:666:777 dpts:123:456 /* ciao */ to:9.8.7.6:54321"
          ],
          [
            2,
            "280",
            "20976",
            "MASQUERADE",
            "all",
            "--",
            "*",
            "eth0",
            "0.0.0.0/0",
            "0.0.0.0/0",
            "--"
          ]
        ],
        "rulespecs": [
          "-s 5.6.7.0/24 -d 1.2.0.0/20 -o eth0 -p tcp -m tcp --sport 666:777 --dport 123:456 -m comment --comment ciao -j SNAT --to-source 9.8.7.6:54321",
          "-o eth0 -j MASQUERADE"
        ]
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
        "rules": [

        ],
        "rulespecs": [

        ]
      }
    }
  }
}
```

Only the POSTROUTING chain is relevant for SNAT.

## Delete a rule
```
PUT /api/v1/network/nat/snat
```

### Body
```javascript
{
  "chain": "POSTROUTING",
  "rulenum": "2",
  "del_rule": true
}
```

Refers to the list of rules [above](#list-rules). Rules are numbered starting from 1.

## Move a rule up/down
```
PUT /api/v1/network/nat/snat
```

### Body
Move up:
```javascript
{
  "chain": "POSTROUTING",
  "rulenum": "2",
  "move_rule_up": true
}
```
Move down:
```javascript
{
  "chain": "POSTROUTING",
  "rulenum": "2",
  "move_rule_down": true
}
```

`rulenum` is the rule order number (which can be inferred after a GET request, see [above](#list-rules)).
Rules are numbered starting from 1.
