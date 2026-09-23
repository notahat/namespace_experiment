# Warehouses

Demonstrates a namespaced pack nested inside a grouping folder. The pack lives
at `packs/inventory/warehouses`, but its namespace is `Warehouses`, not
`Inventory::Warehouses`, because a pack is named by its own directory alone.

`app/models/warehouse.rb` therefore defines `Warehouses::Warehouse`.
