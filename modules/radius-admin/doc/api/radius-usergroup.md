<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  <!--*generated with [DocToc](https://github.com/thlorenz/doctoc)*-->

- [Margay's FreeRADIUS user/group management API v1](#margays-freeradius-usergroup-management-api-v1)
  - [Authentication](#authentication)
  - [List Users](#list-users)
    - [Parameters](#parameters)
    - [Example response](#example-response)
  - [Create User](#create-user)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Margay's FreeRADIUS user/group management API v1

A ReSTful API to manage users and groups on a FreeRADIUS server, in a Margay system. User information is stored in a MySQL database.

Base URLs:

* http://localhost:4567/api/v1/services/radius
* https://localhost/api/v1/services/radius

## Authentication

Unless otherwise noted, use [Basic HTTP Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication)
at each request. The default user is `admin`, password `admin`. Of course, the administrator
is advised to change this in production.

For example, with [cURL](https://curl.haxx.se/), use `curl -u <username>:<password> <URL>`
&mdash; or `curl -u <username> <URL>` and enter the password when prompted.

## List Users

```http
GET http://localhost:4567/api/v1/services/radius/users HTTP/1.1
Host: localhost:4567
Accept: application/json

```

Returns a paginated list of all RADIUS users. A specific page or page size can
be requested via optional parameters e.g.<br/>
`GET /api/v1/services/radius/users?page=2&per_page=7`.

### Parameters

|Name     |In   |Type   |Required |Description                                  |
|---      |---  |---    |---      |---                                          |
|page     |query|integer|false    |page within pagination                       |
|per_page |query|integer|false    |maximum number of results to return per page |

### Example response

```json
{
  "total_items": 1,
  "page": 1,
  "per_page": 10,
  "users": [
    {
      "name": "u1",
      "check": [
        {
          "Id": 1,
          "User-Name": "u1",
          "Attribute": "User-Name",
          "Operator": ":=",
          "Value": "u1"
        },
        {
          "Id": 16,
          "User-Name": "u1",
          "Attribute": "SSHA1-Password",
          "Operator": ":=",
          "Value": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=="
        },
        {
          "Id": 18,
          "User-Name": "u1",
          "Attribute": "Login-Time",
          "Operator": ":=",
          "Value": "Wk2305-0855,Sa,Su2305-1655"
        }
      ],
      "reply": [
        {
          "Id": 6,
          "User-Name": "u1",
          "Attribute": "Reply-Message",
          "Operator": ":=",
          "Value": "my reply msg"
        },
        {
          "Id": 7,
          "User-Name": "u1",
          "Attribute": "Session-Timeout",
          "Operator": ":=",
          "Value": "7200"
        },
        {
          "Id": 8,
          "User-Name": "u1",
          "Attribute": "Idle-Timeout",
          "Operator": ":=",
          "Value": "1800"
        },
        {
          "Id": 9,
          "User-Name": "u1",
          "Attribute": "WISPr-Bandwidth-Max-Down",
          "Operator": ":=",
          "Value": "800000"
        },
        {
          "Id": 10,
          "User-Name": "u1",
          "Attribute": "WISPr-Bandwidth-Max-Up",
          "Operator": ":=",
          "Value": "400000"
        },
        {
          "Id": 110,
          "User-Name": "u1",
          "Attribute": "Fall-Through",
          "Operator": "=",
          "Value": "yes"
        }
      ],
      "groups": [],
      "personal": null,
      "accepted_terms": null
    }
  ]
}
```

## Create User

```http
POST http://localhost:4567/api/v1/services/radius/users HTTP/1.1
Host: localhost:4567
Content-Type: application/json
Accept: application/json

```

Creates a new pet in the store.  TODO
