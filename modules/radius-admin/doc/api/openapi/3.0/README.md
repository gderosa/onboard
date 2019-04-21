YAML files in this directory are from https://github.com/OAI/OpenAPI-Specification/tree/master/examples/v3.0.

The PNG picture of a margay is based on https://commons.wikimedia.org/wiki/File:Margaykat_Leopardus_wiedii.jpg by Malene Thyssen.

See licensing information at the links above.

OpenAPI 3.0 YAML files are converted to HTML thanks to [`api2html`](https://github.com/tobilg/api2html), with the following command line:

```bash
api2html -c 256px-Margaykat_Leopardus_wiedii.png -l shell,http,javascript,python,ruby,go -o html/$FILENAME.html $FILENAME
```