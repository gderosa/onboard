<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents** (<sup>[&loz;](#ndtoc)</sup>)

- [**Margay's Network Interface API v1**](#margays-network-interface-api-v1)
- [*Preliminary info*](#preliminary-info)
  - [Base URLs](#base-urls)
  - [Authentication](#authentication)
  - [RADIUS items overview](#radius-items-overview)
    - [Check Attributes](#check-attributes)
    - [Reply Attributes](#reply-attributes)
- [*Part I. Users*](#part-i-users)
  - [List Users (GET)](#list-users-get)
    - [Parameters](#parameters)
    - [Example response body](#example-response-body)
  - [GET a User](#get-a-user)
    - [Parameters](#parameters-1)
    - [Response body](#response-body)
  - [Create a User (POST)](#create-a-user-post)
    - [Example request body](#example-request-body)
    - [Request body properties](#request-body-properties)
      - [`check` attributes](#check-attributes)
      - [`confirm` attributes](#confirm-attributes)
      - [`reply` attributes](#reply-attributes)
      - [`personal` information](#personal-information)
  - [Modify a User / replace data (PUT)](#modify-a-user--replace-data-put)
    - [Parameters](#parameters-2)
    - [Request body](#request-body)
  - [DELETE a User](#delete-a-user)
    - [Parameters](#parameters-3)
  - [Add/Remove User to Groups (PUT)](#addremove-user-to-groups-put)
    - [Example request body](#example-request-body-1)
    - [Request body properties](#request-body-properties-1)
- [*Part II. Groups*](#part-ii-groups)
  - [Add/Remove Users to a Group (PUT)](#addremove-users-to-a-group-put)
    - [Parameters](#parameters-4)
    - [Example request bodies](#example-request-bodies)
    - [Request body properties](#request-body-properties-2)
  - [List Groups (GET)](#list-groups-get)
    - [Parameters](#parameters-5)
    - [Example response body](#example-response-body-1)
  - [GET info about a Group](#get-info-about-a-group)
    - [Parameters](#parameters-6)
    - [Response body and example](#response-body-and-example)
  - [Create a Group (POST)](#create-a-group-post)
  - [Change attributes of a Group (PUT)](#change-attributes-of-a-group-put)
    - [Parameters](#parameters-7)
    - [Request body](#request-body-1)
  - [DELETE a Group](#delete-a-group)
    - [Parameters](#parameters-8)
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

## RADIUS items overview

This document assumes
[a basic grasp of AAA/RADIUS concepts](https://freeradius.org/documentation/):
user, groups, attributes; or at least an intuition of them once they
are listed and briefly described, and
a basic understanding of the purposes of network
Authentication Authorization and Accouting.

`users` and `groups` keywords will appear, for example,
as part of URLs, and there will be path parameters
such as `:username` and `:groupname`.

RADIUS attribute names such as `Login-Time` or `User-Password` etc.
will appear as JSON properties in various data shapes
within this guide.

"`check`" and "`reply`" will also appear as JSON properties in various
payloads, as they indicate a general classification of RADIUS attributes.

This web service manages *some* attributes in particular, which are believed
useful for most use cases.

Except those explicitly starting with `User-` or `Group-`,
attributes may generally refer to an user and/or to a group.

### Check Attributes

|Name           |Description and possible values|
|---            |---                                                                              |
|"User-Name"    |RADIUS username                                                                  |
|"Group-Name"   |RADIUS group name                                                                |
|"Password-Type"|Any of `SSHA1-Password` (recommended), `SHA1-Password`, `SMD5-Password`, <br/> `MD5-Password`, `Crypt-Password`, `Cleartext-Password`.|
|"User-Password"|The user password.|
|"Auth-Type"    |Sould generaly not be set, unless user must be always accepted (`Accept`) <br/> or rejected (`Reject`).|
|"Login-Time"   |The time span a user may login to the system, more info [here](https://wiki.freeradius.org/config/Users#special-attributes-used-in-the-users-file).|


### Reply Attributes

|Name                       |Description and possible values|
|---                        |---|
|"Reply-Message"            |A post-login message, generally displayed by captive portal popups etc.|
|"Session-Timeout"          |Max connection time (seconds).|
|"Idle-Timeout"             |Max inactivity time (seconds).|
|"WISPr-Bandwidth-Max-Down" |Max Downstream bandwidth (bits/sec).|
|"WISPr-Bandwidth-Max-Up"   |Max Upstream bandwidth (bits/sec).|

# *Part I. Users*

## List Users (GET)

```http
GET http://localhost:4567/api/v1/services/radius/users HTTP/1.1

Accept: application/json
```

Returns a paginated list of all RADIUS users. A specific page or page size can
be requested via optional parameters e.g.<br/>
`GET /api/v1/services/radius/users?page=2&per_page=7`.

### Parameters
<!-- we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3))  |Type   |Required |Description                                  |
|---        |---  |---    |---      |---                                          |
|page       |query|integer|false    |Page within pagination.                      |
|per_page   |query|integer|false    |Maximum number of results to return per page.|

### Example response body

```javascript
{
  "total_items": 1,
  "page": 1,
  "per_page": 10,
  "users": [
    {
      "name": "georgeboole",
      "check": [
        {
          "Id": 1,
          "User-Name": "georgeboole",
          "Attribute": "User-Name",
          "Operator": ":=",
          "Value": "georgeboole"
        },
        {
          "Id": 16,
          "User-Name": "georgeboole",
          "Attribute": "SSHA1-Password",
          "Operator": ":=",
          "Value": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=="
        },
        {
          "Id": 18,
          "User-Name": "georgeboole",
          "Attribute": "Login-Time",
          "Operator": ":=",
          "Value": "Wk2305-0855,Sa,Su2305-1655"
        }
      ],
      "reply": [
        {
          "Id": 6,
          "User-Name": "georgeboole",
          "Attribute": "Reply-Message",
          "Operator": ":=",
          "Value": "my reply msg"
        },
        {
          "Id": 7,
          "User-Name": "georgeboole",
          "Attribute": "Session-Timeout",
          "Operator": ":=",
          "Value": "7200"
        },
        {
          "Id": 8,
          "User-Name": "georgeboole",
          "Attribute": "Idle-Timeout",
          "Operator": ":=",
          "Value": "1800"
        },
        {
          "Id": 9,
          "User-Name": "georgeboole",
          "Attribute": "WISPr-Bandwidth-Max-Down",
          "Operator": ":=",
          "Value": "800000"
        },
        {
          "Id": 10,
          "User-Name": "georgeboole",
          "Attribute": "WISPr-Bandwidth-Max-Up",
          "Operator": ":=",
          "Value": "400000"
        },
        {
          "Id": 110,
          "User-Name": "georgeboole",
          "Attribute": "Fall-Through",
          "Operator": "=",
          "Value": "yes"
        }
      ],
      "groups": [],
      "personal": {
        "Id": 2,
        "User-Name": "georgeboole",
        "First-Name": "George",
        "Last-Name": "Boole",
        "Email": "george.boole@domain",
        "Work-Phone": null,
        "Home-Phone": null,
        "Mobile-Phone": null,
        "Address": null,
        "City": null,
        "State": null,
        "Country": null,
        "Postal-Code": null,
        "Notes": null,
        "Creation-Date": "2019-04-18 18:10:02 +0000",
        "Update-Date": null,
        "Birth-Date": "1815-11-02",
        "Birth-City": null,
        "Birth-State": null,
        "ID-Code": null,
        "Attachments": []
      },
      "accepted_terms": null
    }
  ]
}
```

## GET a User

Retrieve information about a particular user, identified by username.

```http
GET http://localhost:4567/api/v1/services/radius/users/:username HTTP/1.1

Accept: application/json
```

### Parameters
<!-- for "In", we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3)) |Type   |Required |Description                                  |
|---        |---  |---    |---      |---                                          |
|username   |path |string |true     |RADIUS username.                             |

### Response body

An object with just one property, "`user`", whose value is of the same shape of
one element of the array "`users`" in [List Users](#list-users-get).

For example:

```javascript
{
  "user": {
    "name": "georgeboole",
    "check": [
      {
        "Id": 1,
        "User-Name": "georgeboole",
        "Attribute": "User-Name",
        "Operator": ":=",
        "Value": "georgeboole"
      },
      {
        "Id": 16,
        "User-Name": "georgeboole",
        "Attribute": "SSHA1-Password",
        "Operator": ":=",
        "Value": "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=="
      },
      {
        "Id": 18,
        "User-Name": "georgeboole",
        "Attribute": "Login-Time",
        "Operator": ":=",
        "Value": "Wk2305-0855,Sa,Su2305-1655"
      }
    ],
    "reply": [
      {
        "Id": 6,
        "User-Name": "georgeboole",
        "Attribute": "Reply-Message",
        "Operator": ":=",
        "Value": "my reply msg"
      },
      {
        "Id": 7,
        "User-Name": "georgeboole",
        "Attribute": "Session-Timeout",
        "Operator": ":=",
        "Value": "7200"
      },
      {
        "Id": 8,
        "User-Name": "georgeboole",
        "Attribute": "Idle-Timeout",
        "Operator": ":=",
        "Value": "1800"
      },
      {
        "Id": 9,
        "User-Name": "georgeboole",
        "Attribute": "WISPr-Bandwidth-Max-Down",
        "Operator": ":=",
        "Value": "800000"
      },
      {
        "Id": 10,
        "User-Name": "georgeboole",
        "Attribute": "WISPr-Bandwidth-Max-Up",
        "Operator": ":=",
        "Value": "400000"
      },
      {
        "Id": 110,
        "User-Name": "georgeboole",
        "Attribute": "Fall-Through",
        "Operator": "=",
        "Value": "yes"
      }
    ],
    "groups": [
      // ...
    ],
    "personal": [
      // ...
    ],
    "accepted_terms": [
      //
    ]
  }
}
```

## Create a User (POST)

```http
POST http://localhost:4567/api/v1/services/radius/users HTTP/1.1

Content-Type: application/json
Accept: application/json
```

Creates a new RADIUS user.

<a name="create-user-example-body"></a>
### Example request body

```javascript
{
  "check": {
    "User-Name": "georgeboole",
    "Password-Type": "SSHA1-Password",
    "User-Password": "the_password"
  },
  "confirm": {
    "check": {
      "User-Password": "the_password"
    }
  },
  "reply": {
    "Reply-Message": "my reply msg",
    "Session-Timeout": "7200",
    "Idle-Timeout": "1800",
    "WISPr-Bandwidth-Max-Down": "500000",
    "WISPr-Bandwidth-Max-Up": "250000"
  },
  "personal": {
    "First-Name": "George",
    "Last-Name": "Boole",
    "Email": "george.boole@domain",
    "Birth-Date": "1815-11-02"
  }
}
```

### Request body properties

The JSON object sent with the request has four main properties,
each of them has their sub-properties, some are required, some are not.
The example above include all mandatory sub-properties and *some* optional ones.

The main properties are:

* `check`: RADIUS Check Attributes
* `confirm`: Currently only used as a redundancy check for `check` -> `User-Password`
* `reply`: RADIUS Reply Attributes
* `personal`: non-RADIUS information, used to store personal user information for hotspot management; they are all optional

Please note most values (e.g. Idle-Timeout), that are semantically numbers,
are actually encoded as strings (what reported in the tables below is not a mistake).
This is because of the way those data are stored in the RADIUS database,
and this API does not attempt to hide that. Therefore, values will need to be quoted,
e.g. `"Idle-Timeout": "3600"` instead of `"Idle-Timeout": 3600`.

#### `check` attributes

|Parent |Name           |Type   |Required |Description                                                                      |
|---    |---            |---    |---      |---                                                                              |
|"check"|"User-Name"    |string |true     |RADIUS username                                                                  |
|"check"|"Password-Type"|string |true     |Any of `SSHA1-Password` (recommended), <br/> `SHA1-Password`, `SMD5-Password`, `MD5-Password`, <br/> `Crypt-Password`, `Cleartext-Password`.|
|"check"|"User-Password"|string |true     |The user password.|
|"check"|"Auth-Type"    |string |false    |Only set if user must be always accepted (`Accept`) <br/> or rejected (`Reject`).       |
|"check"|"Login-Time"   |string |false    |The time span a user may login to the system, <br/> more info and exmples [here](https://wiki.freeradius.org/config/Users#special-attributes-used-in-the-users-file).|

#### `confirm` attributes

|Parent           |Name                   |Type   |Required |Description                                                                      |
|---              |---                    |---    |---      |---                                                                              |
|"confirm"."check"|"User&#8209;Password"  |string |true     |The value MUST be the same as "check" . "User&#8209;Password"|

#### `reply` attributes

|Parent |Name                       |Type   |Required |Description|
|---    |---                        |---    |---      |---|
|"reply"|"Reply-Message"            |string |false    |A post-login message, generally displayed <br/> by captive portal popups etc.|
|"reply"|"Session-Timeout"          |string |false    |Max connection time (seconds).|
|"reply"|"Idle-Timeout"             |string |false    |Max inactivity time (seconds).|
|"reply"|"WISPr-Bandwidth-Max-Down" |string |false    |Max Downstream bandwidth (bits/sec).|
|"reply"|"WISPr-Bandwidth-Max-Up"   |string |false    |Max Upstream bandwidth (bits/sec).|

#### `personal` information
|Parent     |Name                       |Type   |Required |Description / Info<br/>(if not obvious)|
|---        |---                        |---    |---      |---|
|"personal" |"First-Name"               |string |false    ||
|"personal" |"Last-Name"                |string |false    ||
|"personal" |"Email"                    |string |false    ||
|"personal" |"Birth-Date"               |string |false    |Format: "YYYY-MM-DD" .|
|"personal" |"Birth-City"               |string |false    ||
|"personal" |"Birth-State"              |string |false    |U.S. state, or province, county etc. in other countries.|
|"personal" |"Address"                  |string |false    ||
|"personal" |"City"                     |string |false    ||
|"personal" |"State"                    |string |false    |U.S. state, or province, county etc. in other countries.|
|"personal" |"Postal-Code"              |string |false    ||
|"personal" |"Work-Phone"               |string |false    ||
|"personal" |"Home-Phone"               |string |false    ||
|"personal" |"Mobile-Phone"             |string |false    ||
|"personal" |"ID-Code"                  |string |false    |e.g. Tax code, PPSN, SSN etc.|
|"personal" |"Notes"                    |string |false    |Optional notes, possibly multi-line.|

## Modify a User / replace data (PUT)

```http
PUT http://localhost:4567/api/v1/services/radius/users/:username HTTP/1.1

Content-Type: application/json
Accept: application/json
```

### Parameters
<!-- for "In", we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3)) |Type   |Required |Description                                  |
|---        |---  |---    |---      |---                                          |
|username   |path |string |true     |RADIUS username.                             |

### Request body

Same as in [Create User (POST)](#create-a-user-post), except you can't modify the username.

## DELETE a User

Delete a RADIUS user record.

```http
DELETE http://localhost:4567/api/v1/services/radius/users/:username HTTP/1.1

Accept: application/json
```

### Parameters
<!-- for "In", we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3)) |Type   |Required |Description                                  |
|---        |---  |---    |---      |---                                          |
|username   |path |string |true     |RADIUS username.                             |


## Add/Remove User to Groups (PUT)

```http
PUT http://localhost:4567/api/v1/services/radius/users/:username HTTP/1.1

Content-Type: application/json
Accept: application/json
```

It's the same verb, URL and params as in [Modify a User](#modify-a-user--replace-data-put),
but the request body is different.

### Example request body

```javascript
{
  "update_groups": "on",
  "groups": ["group_A", "group_B"]
}
```

### Request body properties

|Name           |Type   |Required |Description                                                                      |
|---            |---    |---      |---                                                                              |
|"update_groups"|string |true     |MUST be "`on`".                                                                  |
|"groups"       |array  |true     |Array of groups the user should be a member of.                                  |

# *Part II. Groups*

## Add/Remove Users to a Group (PUT)

[Previously](#addremove-user-to-groups-put), we have seen how to add and/or remove
a *single* user to/from one or more groups, by changing the list of gropus she belongs to.
Suppose you want to add a hundred of users to a group, the endpoint
[Add/Remove User to Groups (PUT)](#addremove-user-to-groups-put)
should be called a hundred times, which is unpractical.
This endpoint, instead of adding one user to many groups,
adds many users to one group, thus covering the other use case.
(The same goes for removal).

```http
PUT http://localhost:4567/api/v1/services/radius/groups/:groupname HTTP/1.1

Content-Type: application/json
Accept: application/json
```

### Parameters
<!-- for "In", we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3))  |Type   |Required |Description|
|---        |---              |---    |---      |---|
|groupname  |path             |string |true     |RADIUS group name.|

### Example request bodies

```javascript
{
  "add_members": [
    "user1",
    "user2"
  ]
}
```

```javascript
{
  "remove_members": [
    "user3",
    "user4"
  ]
}
```

### Request body properties

These properties are not all required, but at least one should be present.

|Name             |Type   |Required |Description|
|---              |---    |---      |---|
|"add_members"    |array  |false    |Array of usernames (strings) to be removed from the group.|
|"remove_members" |array  |false    |Array of usernames (strings) to be added to the group.|


## List Groups (GET)

```http
GET http://localhost:4567/api/v1/services/radius/groups HTTP/1.1

Accept: application/json
```

### Parameters

Pagination query parameters e.g.`?page=n&per_page=m` : same as [List Users (GET)](#list-users-get).

### Example response body

It's similar to [List Users (GET)](#list-users-get), both in terms of pagination
and "`check`" and "`reply`" arrays of RADIUS attributes.
See [List Users (GET)](#list-users-get) for a more detailed example.

```javascript
{
  "total_items": 2,
  "page": 1,
  "per_page": 10,
  "groups": [
    {
      "name": "group_A",
      "check": [
        // ...
      ],
      "reply": [
        // ...
      ]
    },
    {
      "name": "group_B",
      "check": [
        // ...
      ],
      "reply": [
        // ...
      ]
    }
  ]
}
```

## GET info about a Group

Retrieve information about a particular group, identified by group name.

```http
GET http://localhost:4567/api/v1/services/radius/groups/:groupname HTTP/1.1

Accept: application/json
```

Pagination on the list of members is also available e.g.\
GET `/api/v1/services/radius/groups/:groupname?page=2&per_page=15`.

### Parameters
<!-- we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3)) |Type   |Required |Description                                      |
|---        |---              |---    |---      |---                                              |
|groupname  |path             |string |true     |RADIUS group name.                               |
|page       |query            |integer|false    |List of members is paginated: page No. to show.  |
|per_page   |query            |integer|false    |List of members is paginated: page size.         |

### Response body and example

The example below is partially truncated.
Several properties and RADIUS attributes for *groups*
are similar to those found for *users* ([List Users](#list-users-get) and [Get A User](#get-a-user)).

There is a "`group`" top-level property, with a subproperty "`name`" whose value is the RADIUS group name.

Other subproperties of "`group`" are "`check`" and "`reply`".
RADIUS groups have *Check* and *Reply* attributes exactly like users, although they are all optional.
Consequently, the values of "`check`" and "`reply`" have respectively the same shape and semantics
of "`user`"->"`check`" and "`user`"->"`reply`" as seen in [Get A User](#get-a-user).

The other top-level property is "`members`". Its values is an object with exactly the same
shape of what returned by
[List Users](#list-users-get), and it's paginated in the same way
&mdash;except, of course, it only includes users belonging to the given RADIUS group.

In the following example, for the group "`g2`", a
[`Login-Time`](https://wiki.freeradius.org/config/Users#special-attributes-used-in-the-users-file)
limit
was set as
from Monday to Friday (`Wk`) from 9:30 AM to 6 PM and Saturday from 10 AM to 2 PM.
Moreover, the upstream bandwidth was limited to 250 kb/s.
If such attributes are not set for he user,
then the group ones will be enforced by a [NAS](http://deployingradius.com/book/concepts/nas.html).

```javascript
{
  "group": {
    "name": "g2",
    "check": [
      {
        "Id": 18,
        "Group-Name": "g2",
        "Attribute": "Login-Time",
        "Operator": ":=",
        "Value": "Wk0930-1800,Sa1000-14000"
      }
    ],
    "reply": [
      {
        "Id": 10,
        "Group-Name": "g2",
        "Attribute": "WISPr-Bandwidth-Max-Up",
        "Operator": ":=",
        "Value": "250000"
      }
    ]
  },
  "members": {
    "total_items": 1,
    "page": 1,
    "per_page": 10,
    "users": [
      {
        "name": "u1",
        "check": [
          // ...
        ],
        "reply": [
          // ...
        ],
        // ...
```

## Create a Group (POST)

```http
POST http://localhost:4567/api/v1/services/radius/groups HTTP/1.1

Content-Type: application/json
Accept: application/json
```

It's similar to [Create a User (POST)](#create-a-user-post), except:
* replace `User-` with `Group-` in all relevant property names of the request body
* there is no "`personal`" information

## Change attributes of a Group (PUT)

```http
PUT http://localhost:4567/api/v1/services/radius/groups/:groupname HTTP/1.1

Content-Type: application/json
Accept: application/json
```

### Parameters
<!-- for "In", we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3))  |Type   |Required |Description|
|---        |---              |---    |---      |---|
|groupname  |path             |string |true     |RADIUS group name.|

### Request body

It's similar to [Create User (POST)](#create-user-example-body), with check and reply atributes, except:
* replace `User-` with `Group-` in all relevant properties in the request body
* there is no "`personal`" information
* you can't modify the `Group-Name`
* setting a `Group-Password` (and "`confirm`") is not necessary

## DELETE a Group

Delete a RADIUS group.

```http
DELETE http://localhost:4567/api/v1/services/radius/groups/:groupname HTTP/1.1

Accept: application/json
```

### Parameters
<!-- for "In", we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In ([*](#noa3))|Type   |Required |Description|
|---        |---            |---    |---      |---|
|groupname  |path           |string |true     |RADIUS group name.|

# *Notes*

(<sup>&loz;</sup>) <a name="ndtoc"></a> Table of Contents generated with [DocToc](https://github.com/thlorenz/doctoc).

(*) <a name="noa3"></a> Although this document is only partially based on the OpenAPI 3.0 specification, the "In" column in a Parameter table follows the parameter-type classification in https://swagger.io/docs/specification/describing-parameters/#types.
