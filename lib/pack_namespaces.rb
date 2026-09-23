# Describes how packs map onto Ruby namespaces.
#
# A pack opts in by setting `automatic_pack_namespace: true` in the metadata
# section of its package.yml. An opted-in pack's ns.rb defines a module named
# after the pack's own directory, and every file under its app/ subdirectories
# defines a constant inside that module, except in the few directories Rails
# expects to hold top-level constants. Folders between the pack root and the
# pack don't contribute to the name. Packs that don't opt in keep packs-rails'
# behaviour, with top-level constants.
#
# Where packs live comes from the `pack_paths` setting in packs.yml, read
# through the packs gem, so this module and the packs gem always agree.
#
# This module only works out the layout. Applying it to Zeitwerk happens in
# config/initializers/pack_namespaces.rb, and teaching packwerk about it
# happens in config/packwerk/pack_namespaces.rb.
module PackNamespaces
  METADATA_KEY = "automatic_pack_namespace".freeze
  NAMESPACE_FILE = "ns.rb".freeze
  UNNAMESPACED_APP_DIRECTORIES = %w[assets helpers javascript views].freeze
  GLOB_CHARACTERS = /[*?\[{]/

  # Raised when a namespaced pack sits inside another namespaced pack. Zeitwerk
  # would nest the inner pack's namespace inside the outer one, contradicting
  # the rule that a pack is named by its own directory alone.
  class NestedNamespaceError < StandardError; end

  # Raised when a pack path in packs.yml has no fixed leading directory to
  # serve as an autoload root, such as `*/packs/*` or the application root.
  class InvalidPackPathError < StandardError; end

  # The Zeitwerk configuration for a pack root: directories to collapse so
  # they don't become namespaces, and paths to leave out of autoloading.
  Layout = Data.define(:collapsed_directories, :ignored_paths)

  class << self
    # Returns the directories, relative to the project root, that must become
    # autoload roots to cover every configured pack path: the fixed leading
    # part of each pattern, with a root inside another root folded into the
    # outer one.
    def pack_roots(pack_paths = Packs::Specification.config.pack_paths)
      roots = pack_paths.map { |pattern| fixed_prefix(pattern) }.uniq
      roots.reject { |root| roots.any? { |other| inside_directory?(root, other) } }
    end

    # Returns the packs that opt in to automatic namespacing, raising if any
    # of them sits inside another.
    def namespaced_packs(packs = Packs.all)
      namespaced = packs.reject(&:is_gem?).select { |pack| namespaced?(pack) }
      namespaced.each { |pack| assert_not_inside_another!(pack, namespaced) }
      namespaced
    end

    # Returns whether a pack's package.yml opts it in to automatic namespacing.
    def namespaced?(pack)
      pack.metadata[METADATA_KEY] == true
    end

    # Returns the subdirectories of a pack's app/ whose files are namespaced.
    def namespaced_app_directories(pack)
      app = pack.path.join("app")
      return [] unless app.directory?

      app.children.select do |child|
        child.directory? && !UNNAMESPACED_APP_DIRECTORIES.include?(child.basename.to_s)
      end
    end

    # Returns whether an autoload path is one packs-rails added for a
    # namespaced pack's app directory, which the packs/ root now covers.
    def superseded_autoload_path?(path, packs)
      packs.any? do |pack|
        app = pack.path.expand_path.to_s
        path = Pathname(path).expand_path
        path.to_s.start_with?("#{app}/app/") && !UNNAMESPACED_APP_DIRECTORIES.include?(path.basename.to_s)
      end
    end

    # Returns the Zeitwerk layout that makes the given packs' namespaces come
    # out right when packs_root is an autoload root.
    def layout(packs_root, packs)
      layout = Layout.new(collapsed_directories: [], ignored_paths: [])
      describe_directory(Pathname(packs_root).expand_path, packs, layout)
      layout
    end

    private

    # Raises if another namespaced pack contains this one.
    def assert_not_inside_another!(pack, packs)
      outer = packs.find { |other| !other.equal?(pack) && inside?(pack, other) }
      return unless outer

      raise NestedNamespaceError,
        "#{pack.name} can't be automatically namespaced because it sits inside " \
        "#{outer.name}, which is namespaced too. Move it out, or opt one of them out."
    end

    # Returns whether one pack's directory lies inside another's.
    def inside?(pack, other)
      inside_directory?(pack.path.expand_path, other.path.expand_path)
    end

    # Returns whether a path lies strictly inside a directory, with both given
    # in the same form, either both relative or both absolute.
    def inside_directory?(path, directory)
      path.to_s.start_with?("#{directory}/")
    end

    # Returns the leading directories of a pack path pattern up to its first
    # glob segment, as a relative path. A pattern with no glob names a single
    # pack, so its root is the pack's parent rather than the pack itself.
    def fixed_prefix(pattern)
      segments = Pathname(pattern).cleanpath.each_filename.reject { |segment| segment == "." }
      fixed = segments.take_while { |segment| !segment.match?(GLOB_CHARACTERS) }
      fixed.pop if fixed.size == segments.size

      if fixed.empty?
        raise InvalidPackPathError,
          "The pack path #{pattern.inspect} in packs.yml needs a fixed leading directory " \
          "to serve as an autoload root."
      end

      Pathname(fixed.join("/"))
    end

    # Describes a directory on the way from packs/ down to one or more
    # namespaced packs. Namespaced packs get their own treatment, folders
    # leading to them are collapsed so they add nothing to the name, and
    # everything else is left out of autoloading.
    def describe_directory(directory, packs, layout)
      directory.children.each do |child|
        if (pack = packs.find { |candidate| candidate.path.expand_path == child })
          describe_pack(pack, layout)
        elsif packs.any? { |candidate| inside_directory?(candidate.path.expand_path, child) }
          layout.collapsed_directories << child
          describe_directory(child, packs, layout)
        elsif autoloadable?(child)
          layout.ignored_paths << child
        end
      end
    end

    # Describes a namespaced pack: app/ and its subdirectories collapse into
    # the pack's namespace, and nothing else in the pack is autoloaded except
    # the namespace file itself.
    def describe_pack(pack, layout)
      app = pack.path.expand_path.join("app")
      layout.collapsed_directories.push(app, app.join("*"), app.join("*/concerns"))
      layout.ignored_paths.concat(UNNAMESPACED_APP_DIRECTORIES.map { |name| app.join(name) })

      pack.path.expand_path.children.each do |child|
        next if child == app || child.basename.to_s == NAMESPACE_FILE

        layout.ignored_paths << child if autoloadable?(child)
      end
    end

    # Returns whether Zeitwerk would try to autoload from the given path.
    def autoloadable?(path)
      path.directory? || path.extname == ".rb"
    end
  end
end
