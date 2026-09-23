require "rails/railtie"
require_relative "layout"

module PackNamespaces
  # Applies the pack namespace layout to Zeitwerk as the application boots.
  #
  # The initializer runs once every engine has registered its autoload paths
  # and before Rails hands them to the main autoloader, which is the only
  # window in which the paths packs-rails adds can still be taken away.
  class Railtie < Rails::Railtie
    initializer "pack_namespaces.configure_autoloader", before: :setup_main_autoloader do |app|
      Autoloader.configure(app.root, Rails.autoloaders.main)
    end
  end

  # Wires the layout into a Zeitwerk loader.
  #
  # Each directory that holds packs, according to the pack paths in packs.yml,
  # becomes an autoload root. Each namespaced pack's ns.rb then defines the
  # pack's module as an ordinary, reloadable constant, and the collapsed and
  # ignored paths from the layout make its app/ files land inside that module.
  # packs-rails adds every pack's app/* directories as autoload roots of their
  # own, and those would win over the pack roots, so the ones belonging to
  # namespaced packs are removed.
  module Autoloader
    class << self
      # Configures the loader for every namespaced pack under the application
      # root.
      def configure(app_root, loader)
        packs = PackNamespaces.namespaced_packs
        loader.nsfile = NAMESPACE_FILE
        PackNamespaces.pack_roots.each { |root| add_root(app_root.join(root), packs, loader) }
        remove_superseded_autoload_paths(packs)
      end

      private

      # Makes a pack root an autoload root, if it exists, with the layout the
      # packs need.
      def add_root(packs_root, packs, loader)
        return unless packs_root.directory?

        layout = PackNamespaces.layout(packs_root, packs)
        loader.push_dir(packs_root)
        layout.collapsed_directories.each { |directory| loader.collapse(directory.to_s) }
        layout.ignored_paths.each { |path| loader.ignore(path.to_s) }
      end

      # Takes away the autoload paths packs-rails added for the given packs'
      # app directories, which the pack roots now cover.
      def remove_superseded_autoload_paths(packs)
        is_superseded = ->(path) { PackNamespaces.superseded_autoload_path?(path, packs) }
        ActiveSupport::Dependencies.autoload_paths.reject!(&is_superseded)
        ActiveSupport::Dependencies._eager_load_paths.delete_if(&is_superseded)
      end
    end
  end
end
