# Catalog

Tracks the books the application knows about and the authors who wrote them.

Everything in this pack lives under the `Catalog` namespace, and every table is
prefixed with `catalog_`. The two models are:

- `Catalog::Author`, who has many books.
- `Catalog::Book`, which belongs to exactly one author.

## Layout

The pack's `package.yml` turns on `automatic_pack_namespace`, so the
automatic_namespaces gem tells Zeitwerk that everything under `app/` belongs to
`Catalog`. Files sit directly in `app/models` without a `catalog/`
subdirectory, and `app/models/book.rb` defines `Catalog::Book`.

The gem creates the `Catalog` module itself, so the table prefix can't live on
the module. Instead, every model inherits from the abstract `Catalog::Record`,
which sets it.

Rails picks up `app/models` here automatically via packs-rails. Migrations stay
in the application's `db/migrate` directory, since packs-rails doesn't add pack
directories to the migration path.

## Running the tests

`bin/rails test` only looks under the top-level `test` directory. To include
this pack's tests, pass both directories:

```sh
bin/rails test test packs
```
