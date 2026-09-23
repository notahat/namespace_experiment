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
in to this with `automatic_pack_namespace: true` in its `package.yml`. The
rules live in `lib/pack_namespaces/layout.rb`, a Railtie in
`lib/pack_namespaces/railtie.rb` applies them to Zeitwerk, and
`lib/pack_namespaces/packwerk.rb` teaches packwerk the same mapping. Helpers,
views, assets and JavaScript are left un-namespaced.

To use this in another application, copy `lib/pack_namespaces.rb` and
`lib/pack_namespaces/`, require the former from `config/application.rb`, add
both to the `autoload_lib` ignore list, and point `packwerk.yml`'s `require`
at the packwerk file.

For a pack nested in a grouping folder, and for a pack that doesn't opt in,
see `packs/inventory/warehouses` and `packs/legacy`.

Where packs live comes from the `pack_paths` setting in `packs.yml`, read
through the packs gem, so packs can be kept under more than one directory.
Each fixed leading directory in those patterns becomes an autoload root.

Migrations stay in the application's `db/migrate` directory, since packs-rails
doesn't add pack directories to the migration path.

## Running the tests

`bin/rails test` only looks under the top-level `test` directory. To include
this pack's tests, pass both directories:

```sh
bin/rails test test packs
```
