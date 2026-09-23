# Applies the pack namespace layout described in lib/pack_namespaces.rb to
# Zeitwerk.
#
# Each directory that holds packs, according to the pack paths in packs.yml,
# becomes an autoload root. Each namespaced pack's ns.rb then defines the
# pack's module as an ordinary, reloadable constant, and the collapsed and
# ignored paths from the layout make its app/ files land inside that module.
# packs-rails adds every pack's app/* directories as autoload roots of their
# own, and those would win over the pack roots, so the ones belonging to
# namespaced packs are removed.
require_relative "../../lib/pack_namespaces"

loader = Rails.autoloaders.main
packs = PackNamespaces.namespaced_packs

loader.nsfile = PackNamespaces::NAMESPACE_FILE

PackNamespaces.pack_roots.each do |root|
  packs_root = Rails.root.join(root)
  next unless packs_root.directory?

  layout = PackNamespaces.layout(packs_root, packs)
  loader.push_dir(packs_root)
  layout.collapsed_directories.each { |directory| loader.collapse(directory.to_s) }
  layout.ignored_paths.each { |path| loader.ignore(path.to_s) }
end

is_superseded = ->(path) { PackNamespaces.superseded_autoload_path?(path, packs) }
ActiveSupport::Dependencies.autoload_paths.reject!(&is_superseded)
ActiveSupport::Dependencies._eager_load_paths.delete_if(&is_superseded)
