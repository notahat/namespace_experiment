# Applies the pack namespace layout described in lib/pack_namespaces.rb to
# Zeitwerk.
#
# packs/ becomes a single autoload root. Each namespaced pack's ns.rb then
# defines the pack's module as an ordinary, reloadable constant, and the
# collapsed and ignored paths from the layout make its app/ files land inside
# that module. packs-rails adds every pack's app/* directories as autoload
# roots of their own, and those would win over the packs/ root, so the ones
# belonging to namespaced packs are removed.
require_relative "../../lib/pack_namespaces"

packs_root = Rails.root.join(PackNamespaces::PACKS_DIRECTORY)

if packs_root.directory?
  loader = Rails.autoloaders.main
  packs = PackNamespaces.namespaced_packs
  layout = PackNamespaces.layout(packs_root, packs)

  loader.nsfile = PackNamespaces::NAMESPACE_FILE
  loader.push_dir(packs_root)
  layout.collapsed_directories.each { |directory| loader.collapse(directory.to_s) }
  layout.ignored_paths.each { |path| loader.ignore(path.to_s) }

  is_superseded = ->(path) { PackNamespaces.superseded_autoload_path?(path, packs) }
  ActiveSupport::Dependencies.autoload_paths.reject!(&is_superseded)
  ActiveSupport::Dependencies._eager_load_paths.delete_if(&is_superseded)
end
