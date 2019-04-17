Spec files in this dir use the old paths for JSON/ReST e.g.
`/services/radius/users.json`. They are just a few,
they were an initial test of the whole testing machinery,
with minimal coverage.

The new JSON/ReST API is under `/api/v*` e.g.
`/api/v1/services/radius/users`, thanks to the
helpers in `lib/onboard/controller/format.rb`.

Their specs are in `../../api/v1/` etc.
and a wider test and codumentation coverage is expected.