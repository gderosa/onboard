A web interface to manage Linux-based network and virtualization
appliances.

This is the web interface for the _Margay_ series of devices by Vemar S.A.S.

It's been mainly developed and tested on Debian GNU/Linux.

## Installation

### On real hardware

Please refer to https://github.com/vemarsas/margay/blob/master/README.md.

### Local development environment

You might want to have a look at https://github.com/vemarsas/margay-vagrant.

## Multiple choices (in the ReST/HTTP sense)

For any web page, you may change `.html` extension into `.json` to
get machine-readable data.

An `.rb` extension is also available for debugging purposes when in
Sinatra `development` environment.

### ReSTful JSON API endpoints and documentation

Besides URLs like e.g. `/services/radius/users.json`, a dedicated
base URL is available at `/api/v1/`.

At the moment, only the RADIUS user/group endpoint is formally
tested and documented ([here](modules/radius-admin/doc/api/)).

As a convenience, if you are working with e.g. the endpoint
`/api/v1/services/radius`, you can be redirected to the documentation
by GET-ting `/api/v1/services/radius/doc`.

## Testing

```bash
# core only
bundle exec rspec

# plus specific module
bundle exec rspec spec modules/radius-admin/spec

# plus all modules
bundle exec rspec spec modules/*/spec
```

It's assumed they have been basically configured to function,
they are real e2e tests connecting to real local db  etc.

## Copying

Except where otherwise stated, this work is
Copyright 2009-2019
Guido De Rosa <guido.derosa at vemarsas.it> and
Antonello Ventre <antonello.ventre at vemarsas.it>.

License: GPLv2

Artworks from various sources are included.
See `public/*/*` for details and Copyright info.
