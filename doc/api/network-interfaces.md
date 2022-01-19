<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents** (<sup>[&loz;](#ndtoc)</sup>)

- [**Margay's Network Interface API v1**](#margays-network-interface-api-v1)
- [*Preliminary info*](#preliminary-info)
  - [Base URLs](#base-urls)
  - [Authentication](#authentication)
- [*Network Interfaces*](#network-interfaces)
  - [List Network Interfaces (GET)](#list-network-interfaces-get)
    - [Parameters](#parameters)
    - [Example response body](#example-response-body)
  - [Modify Network Interface config (PUT)](#modify-network-interface-config-put)
    - [Example Request body](#example-request-body)
- [*Notes*](#notes)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# **Margay's Network Interface API v1**

A ReSTful API to manage network interfaces in a Margay system.

# *Preliminary info*

## Base URLs

* http://localhost:4567/api/v1/network/interfaces
* https://localhost/api/v1/network/interfaces

## Authentication

Unless otherwise noted, use [Basic HTTP Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
at each request. The default user is `admin`, password `admin`. Of course, the administrator
is advised to change this in production.

For example, with [cURL](https://curl.haxx.se/), use `curl -u <username>:<password> <URL>`
&mdash; or `curl -u <username> <URL>` and enter the password when prompted.


# *Network Interfaces*

## List Network Interfaces (GET)

```http
GET http://localhost:4567/api/v1/network/interfaces HTTP/1.1

Accept: application/json
```

Returns the list of all network interfaces, with their IP addresses and other information.

### Parameters
<!-- we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In   |Type   |Required |Description                                                      |
|---        |---  |---    |---      |---                                                              |
|view       |query|string |false    |`view=all` also shows loopbacks, IPv6 link-local addresses etc.  |

### Example response body

```javascript
[
  {
    "name": "lo",
    "misc": [
      "LOOPBACK",
      "UP",
      "LOWER_UP"
    ],
    "qdisc": "noqueue",
    "state": "UP",
    "type": "loopback",
    "active": true,
    "n": 1,
    "mtu": 65536,
    "mac": "00:00:00:00:00:00",
    "ip": [
      {
        "addr": "127.0.0.1",
        "prefixlen": 8,
        "scope": "host",
        "af": "inet"
      },
      {
        "addr": "fe80::8dce:da54:d396:c959",
        "prefixlen": 64,
        "scope": "link",
        "af": "inet6"
      },
      {
        "addr": "::1",
        "prefixlen": 128,
        "scope": "host",
        "af": "inet6"
      }
    ],
    "ipassign": {
      "method": "static",
      "pid": 0,
      "cmd": null,
      "args": null
    },
    "wifi_properties": null
  },
  {
    "name": "eth0",
    "misc": [
      "BROADCAST",
      "MULTICAST",
      "UP",
      "LOWER_UP"
    ],
    "qdisc": "pfifo_fast",
    "state": "UP",
    "type": "ether",
    "vendor": "Standard Microsystems Corp.",
    "model": "",
    "bus": "usb",
    "active": true,
    "n": 2,
    "mtu": 1500,
    "mac": "b8:27:eb:61:dd:6b",
    "ip": [
      {
        "addr": "192.168.177.4",
        "prefixlen": 24,
        "scope": "global",
        "af": "inet"
      },
      {
        "addr": "fe80::ba27:ebff:fe61:dd6b",
        "prefixlen": 64,
        "scope": "link",
        "af": "inet6"
      }
    ],
    "ipassign": {
      "method": "static",
      "pid": 0,
      "cmd": null,
      "args": null
    },
    "wifi_properties": null
  },
  {
    "name": "eth1",
    "misc": [
      "BROADCAST",
      "MULTICAST",
      "UP",
      "LOWER_UP"
    ],
    "qdisc": "pfifo_fast",
    "state": "UP",
    "type": "ether:usbmodem",
    "vendor": "Huawei Technologies Co., Ltd.",
    "model": "E353/E3131",
    "bus": "usb",
    "active": true,
    "n": 4,
    "mtu": 1500,
    "mac": "58:2c:80:13:92:63",
    "ip": [
      {
        "addr": "192.168.1.100",
        "prefixlen": 24,
        "scope": "global",
        "af": "inet"
      },
      {
        "addr": "fe80::92cc:a2cb:f069:501d",
        "prefixlen": 64,
        "scope": "link",
        "af": "inet6"
      }
    ],
    "ipassign": {
      "method": "dhcp",
      "pid": 11135,
      "cmd": "dhcpcd5",
      "args": "-b -p -m 2001 eth1"
    },
    "wifi_properties": null
  },
  {
    "name": "wlan0",
    "misc": [
      "NO-CARRIER",
      "BROADCAST",
      "MULTICAST",
      "UP"
    ],
    "qdisc": "pfifo_fast",
    "state": "NO-CARRIER",
    "type": "wi-fi",
    "vendor": "Broadcom Corp.",
    "model": "BCM43438 combo WLAN and Bluetooth Low Energy (BLE)",
    "bus": "sdio",
    "active": true,
    "n": 3,
    "mtu": 1500,
    "mac": "b8:27:eb:34:88:3e",
    "ip": null,
    "ipassign": {
      "method": "static",
      "pid": 0,
      "cmd": null,
      "args": null
    },
    "wifi_properties": {
      "master": null
    }
  }
]
```

## Modify Network Interface config (PUT)

```http
PUT http://localhost:4567/api/v1/network/interfaces HTTP/1.1

Content-Type: application/json
Accept: application/json
```

### Example Request body

The below example:

* Requests to configure `eth0` with DHCP.
* Set the preferred metric for `eth0` to "empty" i.e. system defaults will be used.
* Kills the DHCP client for `eth1` by setting `"ipassign": {"method": "static"}`.
* Sets the `"ip"[]` addresses for `eth1`.
* Set the preferred metric for `eth1` to `100`.
* Brings the wireless interface `wlan0` down.

Please note, if you want to set the `"ip"` addresses explicitly,
the assignment `"method"` MUST be set to `"static"`,
otherwise the requested IP addresses will be ignored.

```javascript
{
  "netifs": {
    "eth0": {
      "active": true,
      "ip": [
        "192.168.177.4/24",
        "fe80::ba27:ebff:fe61:dd6b/64"
      ],
      "ipassign": {
        "method": "dhcp"
      },
      "preferred_metric": ""
    },
    "eth1": {
      "active": true,
      "ip": [
        "192.168.1.100/24",
        "fe80::92cc:a2cb:f069:501d/64",
        "66.66.66.66/26"
      ],
      "ipassign": {
        "method": "static"
      },
      "preferred_metric": "100"
    },
    "wlan0": {
      "active": false,
      "ipassign": {
        "method": "static"
      },
      "preferred_metric": ""
    }
  }
}
```

Another example: `eth0` will remain managed by DHCP,
but we change the preferred metric for the interface to `200`,
and enforce the new metric immediately by restarting (`"ipassign": {"renew": true}`)
the DHCP client.

```javascript
{
  "netifs": {
    "eth0": {
      "active": true,
      "ipassign": {
        "method": "dhcp",
        "renew": true
      },
      "preferred_metric": 200
    }
  }
}
```

# *Notes*

(<sup>&loz;</sup>) <a name="ndtoc"></a> Table of Contents generated with [DocToc](https://github.com/thlorenz/doctoc).