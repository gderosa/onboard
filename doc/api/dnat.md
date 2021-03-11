# **Margay's IP Routes API v1**

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
