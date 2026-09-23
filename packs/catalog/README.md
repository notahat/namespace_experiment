# Catalog

Tracks the books the application knows about and the authors who wrote them.

Everything in this pack lives under the `Catalog` namespace, and every table is
prefixed with `catalog_`. The two models are:

- `Catalog::Author`, who has many books.
- `Catalog::Book`, which belongs to exactly one author.

## Layout

`ns.rb` at the root of the pack defines the `Catalog` module. It's an ordinary
autoloaded file, so it can carry class methods (the table prefix lives there)
and it reloads in development like any other constant.

Files under `app/` sit directly in the namespace without a `catalog/`
subdirectory, so `app/models/book.rb` defines `Catalog::Book`. The pack opts
in to this with `automatic_pack_namespace: true` in its `package.yml`; the
rules live in `lib/pack_namespaces.rb` and are applied to Zeitwerk by
`config/initializers/pack_namespaces.rb`. Helpers, views, assets and
JavaScript are left un-namespaced. `config/packwerk/pack_namespaces.rb`
teaches packwerk the same mapping.

For a pack nested in a grouping folder, and for a pack that doesn't opt in,
see `packs/inventory/warehouses` and `packs/legacy`.

Migrations stay in the application's `db/migrate` directory, since packs-rails
doesn't add pack directories to the migration path.

## Running the tests

`bin/rails test` only looks under the top-level `test` directory. To include
this pack's tests, pass both directories:

```sh
bin/rails test test packs
```
