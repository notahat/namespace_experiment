# Automatic, reloadable namespaces for packs.
#
# Requiring this file from config/application.rb is all a Rails application
# needs: the Railtie applies the layout to Zeitwerk as the application boots.
# The packwerk side lives in pack_namespaces/packwerk.rb and is loaded through
# packwerk.yml instead, since packwerk isn't always present.
require_relative "pack_namespaces/layout"
require_relative "pack_namespaces/railtie"
