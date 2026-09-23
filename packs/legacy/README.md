# Legacy

Demonstrates a pack that has not opted in to automatic namespacing. Its
`package.yml` has no `automatic_pack_namespace` metadata, so packs-rails loads
its `app/` directories as ordinary autoload roots and `app/models/legacy_report.rb`
defines a top-level `LegacyReport`.
