<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents** (<sup>[&loz;](#ndtoc)</sup>)

- [**Margay's IP Routes API v1**](#margays-ip-routes-api-v1)
- [*Preliminary info*](#preliminary-info)
  - [Base URLs](#base-urls)
  - [Authentication](#authentication)
- [*IP routes*](#ip-routes)
  - [List Routes (Main routing table) (GET)](#list-routes-main-routing-table-get)
    - [Example response body](#example-response-body)
  - [Modify Network Interface config (PUT)](#modify-network-interface-config-put)
    - [Example Request body](#example-request-body)
- [*Notes*](#notes)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# **Margay's IP Routes API v1**

A ReSTful API to manage [IP routes](https://wiki.linuxfoundation.org/networking/iproute2) in a Margay system.

# *Preliminary info*

## Base URLs

* http://localhost:4567/api/v1/routing/&lt;tables|rules&gt;
* https://localhost/api/v1/network/routing/&lt;tables|rules&gt;

## Authentication

Unless otherwise noted, use [Basic HTTP Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
at each request. The default user is `admin`, password `admin`. Of course, the administrator
is advised to change this in production.

For example, with [cURL](https://curl.haxx.se/), use `curl -u <username>:<password> <URL>`
&mdash; or `curl -u <username> <URL>` and enter the password when prompted.


# *IP routes*

## List Routes (Main routing table) (GET)

```http
GET http://localhost:4567/api/v1/network/routing/tables/main HTTP/1.1

Accept: application/json
```

Returns the list of all the IP routes in the `main` table.

### Example response body

```javascript
{
  "number": 254,
  "name": "main",
  "system": [
    254,
    "main"
  ],
  "routes": [
    {
      "rttype": "unicast",
      "dest": {
        "addr": "0.0.0.0",
        "prefixlen": 0,
        "af": "inet"
      },
      "gw": "192.168.177.1",
      "dev": "eth0",
      "proto": null,
      "metric": 1203,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": null,
      "src": "192.168.177.4",
      "rawline": "default via 192.168.177.1 dev eth0 src 192.168.177.4 metric 1203"
    },
    {
      "rttype": "unicast",
      "dest": {
        "addr": "2.2.2.2",
        "prefixlen": 32,
        "af": "inet"
      },
      "gw": null,
      "dev": "eth1",
      "proto": "static",
      "metric": 204,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": "link",
      "src": null,
      "rawline": "2.2.2.2 dev eth1  scope link metric 204"
    },
    {
      "rttype": "unicast",
      "dest": {
        "addr": "127.0.0.0",
        "prefixlen": 8,
        "af": "inet"
      },
      "gw": null,
      "dev": "lo",
      "proto": "kernel",
      "metric": 201,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": "host",
      "src": "127.0.0.1",
      "rawline": "127.0.0.0/8 dev lo  scope host src 127.0.0.1 metric 201"
    },
    {
      "rttype": "unicast",
      "dest": {
        "addr": "192.168.177.0",
        "prefixlen": 24,
        "af": "inet"
      },
      "gw": null,
      "dev": "eth0",
      "proto": "kernel",
      "metric": 1203,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": "link",
      "src": "192.168.177.4",
      "rawline": "192.168.177.0/24 dev eth0  scope link src 192.168.177.4 metric 1203"
    },
    {
      "rttype": "unicast",
      "dest": {
        "addr": "::1",
        "prefixlen": 128,
        "af": "inet6"
      },
      "gw": null,
      "dev": "lo",
      "proto": "kernel",
      "metric": 256,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": null,
      "src": null,
      "rawline": "::1 dev lo  metric 256 pref medium"
    },
    {
      "rttype": "unicast",
      "dest": {
        "addr": "fe80::",
        "prefixlen": 64,
        "af": "inet6"
      },
      "gw": null,
      "dev": "lo",
      "proto": "kernel",
      "metric": 256,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": null,
      "src": null,
      "rawline": "fe80::/64 dev lo  metric 256 pref medium"
    },
    {
      "rttype": "unicast",
      "dest": {
        "addr": "fe80::",
        "prefixlen": 64,
        "af": "inet6"
      },
      "gw": null,
      "dev": "eth1",
      "proto": "kernel",
      "metric": 256,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": null,
      "src": null,
      "rawline": "fe80::/64 dev eth1  metric 256 pref medium"
    },
    {
      "rttype": "unicast",
      "dest": {
        "addr": "fe80::",
        "prefixlen": 64,
        "af": "inet6"
      },
      "gw": null,
      "dev": "eth0",
      "proto": "kernel",
      "metric": 256,
      "mtu": null,
      "advmss": null,
      "error": null,
      "hoplimit": null,
      "scope": null,
      "src": null,
      "rawline": "fe80::/64 dev eth0  metric 256 pref medium"
    }
  ]
}
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