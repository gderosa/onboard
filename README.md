A web interface to manage Linux-based network and virtualization
appliances.

This is the web interface for the _Margay_ series of devices by Vemar S.A.S.

It's been mainly developed and tested on Debian GNU/Linux.

## Installation

### On real hardware

Please refer to https://github.com/vemarsas/margay/blob/master/README.md.

### Local development environment

You can install Vagrant -- https://www.vagrantup.com/.

Then run

```bash
vagrant up
```

You can also start separately margay vm and client vm:

```bash
vagrant up margay
```
```bash
vagrant up client
```

The client VM will show the VBox GUI, you will see a graphical login.
Enter with credentials vagrant:vagrant, then right-click
and open Web Browser (or Terminal etc.)

The same distinction between margay and client machine holds for
other Vagrant commands: provision, halt, suspend, destroy etc.
(see documentation on the Vagrant website).

#### Hotspot/RADIUS module

Enable with (from the host):

```
vagrant provision margay --provision-with radius
```

#### Very optional Vagrant tweaks

##### Proxy

If you install the vagrant-proxyconf plugin,
you also set proxy environment variables if you want to use a proxy
for downloading packages during provisioning etc.

See https://github.com/tmatilai/vagrant-proxyconf#environment-variables for more.

Suggested values (from the host!) are

```bash
VAGRANT_HTTP_PROXY=http://10.0.2.2:8123
VAGRANT_HTTPS_PROXY=http://10.0.2.2:8123
```
if, for example, you use polipo with default config
(10.0.2.2 is the default gateway for vbox NAT interface in the vm).

Beware this may conflict with capitive portal in the client, as browsers will then use the proxy
and therefore circumvent the captive portal (depending on the configuration).

##### Keeping Guest Additions updated

```
vagrant plugin install vagrant-vbguest  # optional, ensure updated VBox Guest Additions in the vm
```

## After installation

Margay server will be available at

* http://localhost:4567
* https://localhost:4443

The default credentials are `admin`:`admin`.

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
