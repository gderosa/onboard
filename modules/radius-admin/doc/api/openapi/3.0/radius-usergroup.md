---
title: Margay's FreeRADIUS user/group management API
language_tabs:
  - shell: Shell
  - http: HTTP
  - javascript: JavaScript
  - javascript--nodejs: Node.JS
  - ruby: Ruby
  - python: Python
  - java: Java
  - go: Go
toc_footers: []
includes: []
search: true
highlight_theme: darkula
headingLevel: 2

---

<h1 id="margay-s-freeradius-user-group-management-api">Margay's FreeRADIUS user/group management API v1</h1>

> Scroll down for code samples, example requests and responses. Select a language for code samples from the tabs above or the mobile navigation menu.

A ReSTful API to manage users and groups on a FreeRADIUS server, in a Margay system. User information is stored in a MySQL database.

Base URLs:

* <a href="http://localhost:4567/api/v1">http://localhost:4567/api/v1</a>

Email: <a href="mailto:dev@vemarsas.it">Vemar S.A.S. Dev Team</a> Web: <a href="https://github.com/vemarsas/onboard/modules/radius-admin">Vemar S.A.S. Dev Team</a> 
License: <a href="https://www.gnu.org/licenses/gpl-2.0.html">GPL 2.0</a>

<h1 id="margay-s-freeradius-user-group-management-api-users">Users</h1>

## List Users

<a id="opIdList Users"></a>

> Code samples

```shell
# You can also use wget
curl -X GET http://localhost:4567/api/v1/services/radius/users \
  -H 'Accept: application/json'

```

```http
GET http://localhost:4567/api/v1/services/radius/users HTTP/1.1
Host: localhost:4567
Accept: application/json

```

```javascript
var headers = {
  'Accept':'application/json'

};

$.ajax({
  url: 'http://localhost:4567/api/v1/services/radius/users',
  method: 'get',

  headers: headers,
  success: function(data) {
    console.log(JSON.stringify(data));
  }
})

```

```javascript--nodejs
const fetch = require('node-fetch');

const headers = {
  'Accept':'application/json'

};

fetch('http://localhost:4567/api/v1/services/radius/users',
{
  method: 'GET',

  headers: headers
})
.then(function(res) {
    return res.json();
}).then(function(body) {
    console.log(body);
});

```

```ruby
require 'rest-client'
require 'json'

headers = {
  'Accept' => 'application/json'
}

result = RestClient.get 'http://localhost:4567/api/v1/services/radius/users',
  params: {
  }, headers: headers

p JSON.parse(result)

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://localhost:4567/api/v1/services/radius/users', params={

}, headers = headers)

print r.json()

```

```java
URL obj = new URL("http://localhost:4567/api/v1/services/radius/users");
HttpURLConnection con = (HttpURLConnection) obj.openConnection();
con.setRequestMethod("GET");
int responseCode = con.getResponseCode();
BufferedReader in = new BufferedReader(
    new InputStreamReader(con.getInputStream()));
String inputLine;
StringBuffer response = new StringBuffer();
while ((inputLine = in.readLine()) != null) {
    response.append(inputLine);
}
in.close();
System.out.println(response.toString());

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
        
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "http://localhost:4567/api/v1/services/radius/users", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /services/radius/users`

Returns a paginated list of all RADIUS users. A specific page or page size can
be requested via optional parameters e.g.<br/>
`GET /api/v1/services/radius/users?page=2&per_page=7`.

<h3 id="list-users-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|page|query|integer|false|page within pagination|
|per_page|query|integer|false|maximum number of results to return per page|

> Example responses

> Paginated list of users

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
          "Value": "Yg+Zkt25hotWV4vLYXcEjGZv153BmsHJMilz0+XT15W5J4S78ieoZQ=="
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

<h3 id="list-users-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|Paginated list of users|[PaginatedUsers](#schemapaginatedusers)|

<aside class="success">
This operation does not require authentication
</aside>

<h1 id="margay-s-freeradius-user-group-management-api-endpoints">Endpoints</h1>

## addPet

<a id="opIdaddPet"></a>

> Code samples

```shell
# You can also use wget
curl -X POST http://localhost:4567/api/v1/services/radius/users \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json'

```

```http
POST http://localhost:4567/api/v1/services/radius/users HTTP/1.1
Host: localhost:4567
Content-Type: application/json
Accept: application/json

```

```javascript
var headers = {
  'Content-Type':'application/json',
  'Accept':'application/json'

};

$.ajax({
  url: 'http://localhost:4567/api/v1/services/radius/users',
  method: 'post',

  headers: headers,
  success: function(data) {
    console.log(JSON.stringify(data));
  }
})

```

```javascript--nodejs
const fetch = require('node-fetch');
const inputBody = '{
  "name": "string",
  "tag": "string"
}';
const headers = {
  'Content-Type':'application/json',
  'Accept':'application/json'

};

fetch('http://localhost:4567/api/v1/services/radius/users',
{
  method: 'POST',
  body: inputBody,
  headers: headers
})
.then(function(res) {
    return res.json();
}).then(function(body) {
    console.log(body);
});

```

```ruby
require 'rest-client'
require 'json'

headers = {
  'Content-Type' => 'application/json',
  'Accept' => 'application/json'
}

result = RestClient.post 'http://localhost:4567/api/v1/services/radius/users',
  params: {
  }, headers: headers

p JSON.parse(result)

```

```python
import requests
headers = {
  'Content-Type': 'application/json',
  'Accept': 'application/json'
}

r = requests.post('http://localhost:4567/api/v1/services/radius/users', params={

}, headers = headers)

print r.json()

```

```java
URL obj = new URL("http://localhost:4567/api/v1/services/radius/users");
HttpURLConnection con = (HttpURLConnection) obj.openConnection();
con.setRequestMethod("POST");
int responseCode = con.getResponseCode();
BufferedReader in = new BufferedReader(
    new InputStreamReader(con.getInputStream()));
String inputLine;
StringBuffer response = new StringBuffer();
while ((inputLine = in.readLine()) != null) {
    response.append(inputLine);
}
in.close();
System.out.println(response.toString());

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Content-Type": []string{"application/json"},
        "Accept": []string{"application/json"},
        
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("POST", "http://localhost:4567/api/v1/services/radius/users", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`POST /services/radius/users`

Creates a new pet in the store.  Duplicates are allowed

> Body parameter

```json
{
  "name": "string",
  "tag": "string"
}
```

<h3 id="addpet-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|body|body|[NewPet](#schemanewpet)|true|Pet to add to the store|

> Example responses

> default Response

```json
{
  "code": 0,
  "message": "string"
}
```

<h3 id="addpet-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|pet response|None|
|default|Default|unexpected error|[Error](#schemaerror)|

<h3 id="addpet-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## find pet by id

<a id="opIdfind pet by id"></a>

> Code samples

```shell
# You can also use wget
curl -X GET http://localhost:4567/api/v1/pets/{id} \
  -H 'Accept: application/json'

```

```http
GET http://localhost:4567/api/v1/pets/{id} HTTP/1.1
Host: localhost:4567
Accept: application/json

```

```javascript
var headers = {
  'Accept':'application/json'

};

$.ajax({
  url: 'http://localhost:4567/api/v1/pets/{id}',
  method: 'get',

  headers: headers,
  success: function(data) {
    console.log(JSON.stringify(data));
  }
})

```

```javascript--nodejs
const fetch = require('node-fetch');

const headers = {
  'Accept':'application/json'

};

fetch('http://localhost:4567/api/v1/pets/{id}',
{
  method: 'GET',

  headers: headers
})
.then(function(res) {
    return res.json();
}).then(function(body) {
    console.log(body);
});

```

```ruby
require 'rest-client'
require 'json'

headers = {
  'Accept' => 'application/json'
}

result = RestClient.get 'http://localhost:4567/api/v1/pets/{id}',
  params: {
  }, headers: headers

p JSON.parse(result)

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.get('http://localhost:4567/api/v1/pets/{id}', params={

}, headers = headers)

print r.json()

```

```java
URL obj = new URL("http://localhost:4567/api/v1/pets/{id}");
HttpURLConnection con = (HttpURLConnection) obj.openConnection();
con.setRequestMethod("GET");
int responseCode = con.getResponseCode();
BufferedReader in = new BufferedReader(
    new InputStreamReader(con.getInputStream()));
String inputLine;
StringBuffer response = new StringBuffer();
while ((inputLine = in.readLine()) != null) {
    response.append(inputLine);
}
in.close();
System.out.println(response.toString());

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
        
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("GET", "http://localhost:4567/api/v1/pets/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`GET /pets/{id}`

Returns a user based on a single ID, if the user does not have access to the pet

<h3 id="find-pet-by-id-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|integer(int64)|true|ID of pet to fetch|

> Example responses

> default Response

```json
{
  "code": 0,
  "message": "string"
}
```

<h3 id="find-pet-by-id-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|200|[OK](https://tools.ietf.org/html/rfc7231#section-6.3.1)|pet response|None|
|default|Default|unexpected error|[Error](#schemaerror)|

<h3 id="find-pet-by-id-responseschema">Response Schema</h3>

<aside class="success">
This operation does not require authentication
</aside>

## deletePet

<a id="opIddeletePet"></a>

> Code samples

```shell
# You can also use wget
curl -X DELETE http://localhost:4567/api/v1/pets/{id} \
  -H 'Accept: application/json'

```

```http
DELETE http://localhost:4567/api/v1/pets/{id} HTTP/1.1
Host: localhost:4567
Accept: application/json

```

```javascript
var headers = {
  'Accept':'application/json'

};

$.ajax({
  url: 'http://localhost:4567/api/v1/pets/{id}',
  method: 'delete',

  headers: headers,
  success: function(data) {
    console.log(JSON.stringify(data));
  }
})

```

```javascript--nodejs
const fetch = require('node-fetch');

const headers = {
  'Accept':'application/json'

};

fetch('http://localhost:4567/api/v1/pets/{id}',
{
  method: 'DELETE',

  headers: headers
})
.then(function(res) {
    return res.json();
}).then(function(body) {
    console.log(body);
});

```

```ruby
require 'rest-client'
require 'json'

headers = {
  'Accept' => 'application/json'
}

result = RestClient.delete 'http://localhost:4567/api/v1/pets/{id}',
  params: {
  }, headers: headers

p JSON.parse(result)

```

```python
import requests
headers = {
  'Accept': 'application/json'
}

r = requests.delete('http://localhost:4567/api/v1/pets/{id}', params={

}, headers = headers)

print r.json()

```

```java
URL obj = new URL("http://localhost:4567/api/v1/pets/{id}");
HttpURLConnection con = (HttpURLConnection) obj.openConnection();
con.setRequestMethod("DELETE");
int responseCode = con.getResponseCode();
BufferedReader in = new BufferedReader(
    new InputStreamReader(con.getInputStream()));
String inputLine;
StringBuffer response = new StringBuffer();
while ((inputLine = in.readLine()) != null) {
    response.append(inputLine);
}
in.close();
System.out.println(response.toString());

```

```go
package main

import (
       "bytes"
       "net/http"
)

func main() {

    headers := map[string][]string{
        "Accept": []string{"application/json"},
        
    }

    data := bytes.NewBuffer([]byte{jsonReq})
    req, err := http.NewRequest("DELETE", "http://localhost:4567/api/v1/pets/{id}", data)
    req.Header = headers

    client := &http.Client{}
    resp, err := client.Do(req)
    // ...
}

```

`DELETE /pets/{id}`

deletes a single pet based on the ID supplied

<h3 id="deletepet-parameters">Parameters</h3>

|Name|In|Type|Required|Description|
|---|---|---|---|---|
|id|path|integer(int64)|true|ID of pet to delete|

> Example responses

> default Response

```json
{
  "code": 0,
  "message": "string"
}
```

<h3 id="deletepet-responses">Responses</h3>

|Status|Meaning|Description|Schema|
|---|---|---|---|
|204|[No Content](https://tools.ietf.org/html/rfc7231#section-6.3.5)|pet deleted|None|
|default|Default|unexpected error|[Error](#schemaerror)|

<aside class="success">
This operation does not require authentication
</aside>

# Schemas

<h2 id="tocSpaginatedusers">PaginatedUsers</h2>

<a id="schemapaginatedusers"></a>

```json
{
  "total_items": 0,
  "page": 0,
  "per_page": 0,
  "users": [
    {
      "id": 0
    }
  ]
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|total_items|integer|true|read-only|total number of users|
|page|integer|true|read-only|page within pagination|
|per_page|integer|true|read-only|number of users per page|
|users|[[User](#schemauser)]|true|read-only|array of User objects|

<h2 id="tocSuser">User</h2>

<a id="schemauser"></a>

```json
{
  "id": 0
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|id|integer(int64)|true|none|none|

<h2 id="tocSnewpet">NewPet</h2>

<a id="schemanewpet"></a>

```json
{
  "name": "string",
  "tag": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|name|string|true|none|none|
|tag|string|false|none|none|

<h2 id="tocSerror">Error</h2>

<a id="schemaerror"></a>

```json
{
  "code": 0,
  "message": "string"
}

```

### Properties

|Name|Type|Required|Restrictions|Description|
|---|---|---|---|---|
|code|integer(int32)|true|none|none|
|message|string|true|none|none|

