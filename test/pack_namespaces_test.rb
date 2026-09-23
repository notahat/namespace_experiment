require "test_helper"
require "tmpdir"

# Covers lib/pack_namespaces.rb as applied by
# config/initializers/pack_namespaces.rb, using the packs in the repository as
# examples. Asking the autoloader which constant it expects a file to define
# proves the mapping without depending on what any particular file contains.
class PackNamespacesTest < ActiveSupport::TestCase
  test "a namespaced pack's ns.rb defines the pack's namespace" do
    assert_equal "Catalog", expected_constant_for("packs/catalog/ns.rb")
  end

  test "a namespaced pack's models live directly in its namespace" do
    assert_equal "Catalog::Book", expected_constant_for("packs/catalog/app/models/book.rb")
  end

  test "a namespaced pack's tests are not autoloaded" do
    assert_nil expected_constant_for("packs/catalog/test/models/book_test.rb")
  end

  test "a namespaced pack's namespace can define class methods" do
    assert_equal "catalog_", Catalog.table_name_prefix
  end

  test "a pack inside a grouping folder is named by its own directory alone" do
    assert_equal "Warehouses", expected_constant_for("packs/inventory/warehouses/ns.rb")
    assert_equal "Warehouses::Warehouse", expected_constant_for("packs/inventory/warehouses/app/models/warehouse.rb")
  end

  test "a pack that hasn't opted in keeps top-level constants" do
    assert_equal "LegacyReport", expected_constant_for("packs/legacy/app/models/legacy_report.rb")
  end

  test "refuses a namespaced pack inside another namespaced pack" do
    Dir.mktmpdir do |root|
      outer = namespaced_pack_at(root, "packs/outer")
      inner = namespaced_pack_at(root, "packs/outer/inner")

      error = assert_raises(PackNamespaces::NestedNamespaceError) do
        PackNamespaces.namespaced_packs([ outer, inner ])
      end

      assert_includes error.message, "packs/outer/inner"
      assert_includes error.message, "packs/outer"
    end
  end

  private

  # Returns the constant path Zeitwerk expects the given project-relative file
  # to define, or nil if the file is ignored.
  def expected_constant_for(relative_path)
    Rails.autoloaders.main.cpath_expected_at(Rails.root.join(relative_path))
  end

  # Creates a pack on disk under the given root whose package.yml opts in to
  # automatic namespacing, and returns it.
  def namespaced_pack_at(root, name)
    path = Pathname(root).join(name)
    path.mkpath
    path.join("package.yml").write({ "metadata" => { PackNamespaces::METADATA_KEY => true } }.to_yaml)
    Packs::Pack.new(name: name, path: path, relative_path: Pathname(name))
  end
end
