# Teaches packwerk about the pack namespaces described in
# lib/pack_namespaces.rb and applied to Zeitwerk in
# config/initializers/pack_namespaces.rb.
#
# Packwerk maps files to constant names by camelizing each file's path
# relative to a Zeitwerk root directory. It doesn't understand collapsed
# directories or nsfiles, so with packs/ as an autoload root it would believe
# packs/catalog/app/models/book.rb defines Packs::Catalog::App::Models::Book.
# This file fixes that in two places:
#
# - PackNamespaceLoadPaths replaces each pack root with one load path per
#   namespaced app directory, each mapped to its pack's namespace, so packwerk
#   sees Catalog::Book.
# - PackNamespaceFiles adds each namespaced pack's ns.rb to the resolver's
#   file map as the definition of the namespace module itself, so a reference
#   to bare Catalog is attributed to the pack too.
#
# Both ask Zeitwerk for each pack's namespace, so inflection overrides and the
# collapsing of grouping folders are honoured without repeating the rules.
require "constant_resolver"
require_relative "../../lib/pack_namespaces"

# Overrides Packwerk::Configuration#load_paths. See the file comment.
module PackNamespaceLoadPaths
  # Returns packwerk's Rails-derived load paths with the pack roots swapped
  # for namespaced per-pack app directories.
  def load_paths
    @load_paths ||= super.reject { |path, _| pack_roots.include?(path) }.merge(pack_load_paths)
  end

  private

  # Returns the pack roots as packwerk names load paths: relative to the
  # project root, as strings.
  def pack_roots
    PackNamespaces.pack_roots.map(&:to_s)
  end

  # Returns a hash from each namespaced app directory, relative to the project
  # root, to the namespace module its files define constants in.
  def pack_load_paths
    PackNamespaces.namespaced_packs.each_with_object({}) do |pack, load_paths|
      namespace = Object.const_get(Rails.autoloaders.main.cpath_expected_at(pack.path))
      PackNamespaces.namespaced_app_directories(pack).each do |directory|
        load_paths[directory.relative_path_from(Rails.root).to_s] = namespace
      end
    end
  end
end

# Overrides ConstantResolver#file_map. See the file comment.
module PackNamespaceFiles
  # Returns the resolver's map from constant name to defining file, with an
  # entry for each namespaced pack's namespace module added.
  def file_map
    @file_map_with_pack_namespaces ||= super.merge(pack_namespace_files)
  end

  private

  # Returns a hash from each namespaced pack's constant name to the
  # project-relative path of the ns.rb file that defines it.
  def pack_namespace_files
    PackNamespaces.namespaced_packs.filter_map do |pack|
      namespace_file = pack.path.join(PackNamespaces::NAMESPACE_FILE)
      next unless namespace_file.file?

      [ Rails.autoloaders.main.cpath_expected_at(pack.path), namespace_file.relative_path_from(Rails.root).to_s ]
    end.to_h
  end
end

Packwerk::Configuration.prepend(PackNamespaceLoadPaths)
ConstantResolver.prepend(PackNamespaceFiles)
