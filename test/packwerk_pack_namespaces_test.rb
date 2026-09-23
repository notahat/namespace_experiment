require "test_helper"
require "packwerk"
require "constant_resolver"

# Covers config/packwerk/pack_namespaces.rb by loading the project's packwerk
# configuration, which pulls the extension in through packwerk.yml, and
# checking what it tells packwerk about the packs in the repository.
class PackwerkPackNamespacesTest < ActiveSupport::TestCase
  test "maps a namespaced pack's app directories to its namespace" do
    assert_equal Catalog, load_paths["packs/catalog/app/models"]
  end

  test "names a pack inside a grouping folder by its own directory alone" do
    assert_equal Warehouses, load_paths["packs/inventory/warehouses/app/models"]
  end

  test "leaves an opted-out pack's app directories at the top level" do
    assert_equal Object, load_paths["packs/legacy/app/models"]
  end

  test "does not treat the packs directory itself as a load path" do
    assert_nil load_paths["packs"]
  end

  test "attributes a namespace module to its pack's ns.rb" do
    assert_equal "packs/catalog/ns.rb", resolver.resolve("Catalog").location
  end

  test "attributes a constant inside a namespace to the file that defines it" do
    assert_equal "packs/catalog/app/models/book.rb", resolver.resolve("Catalog::Book").location
  end

  private

  # Returns the project's packwerk configuration, with the extension loaded.
  def configuration
    @configuration ||= Packwerk::Configuration.from_path(Rails.root.to_s)
  end

  # Returns packwerk's map from load path to namespace.
  def load_paths
    configuration.load_paths
  end

  # Returns a constant resolver set up the way packwerk sets one up.
  def resolver
    ConstantResolver.new(root_path: configuration.root_path, load_paths: load_paths)
  end
end
