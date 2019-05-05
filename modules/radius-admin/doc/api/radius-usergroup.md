<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  <!--*generated with [DocToc](https://github.com/thlorenz/doctoc)*-->

- [Margay's FreeRADIUS user/group management API v1](#margays-freeradius-usergroup-management-api-v1)
  - [Authentication](#authentication)
  - [List Users](#list-users)
    - [Parameters](#parameters)
    - [Example response](#example-response)
  - [Create User](#create-user)
    - [Example request body](#example-request-body)
    - [Request body properties](#request-body-properties)
      - [`check` attributes](#check-attributes)
      - [`confirm` attributes](#confirm-attributes)
      - [`reply` attributes](#reply-attributes)
      - [`personal` information](#personal-information)
  - [Modify User](#modify-user)
    - [Parameters](#parameters-1)
    - [Request body](#request-body)

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
<!-- we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In   |Type   |Required |Description                                  |
|---        |---  |---    |---      |---                                          |
|"page"     |query|integer|false    |Page within pagination.                      |
|"per_page" |query|integer|false    |Maximum number of results to return per page.|

### Example response

```json
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
        "User-Name": "__user_test",
        "First-Name": "George",
        "Last-Name": "Boole",
        "Email": "george.boole@ucc.ie",
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

## Create User

```http
POST http://localhost:4567/api/v1/services/radius/users HTTP/1.1
Host: localhost:4567
Content-Type: application/json
Accept: application/json
```

Creates a new RADIUS user.

### Example request body

```json
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

## Modify User

```http
PUT http://localhost:4567/api/v1/services/radius/users/{username} HTTP/1.1
Host: localhost:4567
Content-Type: application/json
Accept: application/json
```

### Parameters
<!-- we try to follow this classification, as possible: https://swagger.io/docs/specification/describing-parameters/ -->
|Name       |In   |Type   |Required |Description                                  |
|---        |---  |---    |---      |---                                          |
|username   |path |string |true     |RADIUS username.                             |

### Request body

Same as in [Create User](#create-user), except you can't modify the username.
