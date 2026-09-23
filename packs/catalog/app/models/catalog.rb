# The Catalog namespace holds the books and authors the application tracks.
# Every model in this namespace lives in a table prefixed with "catalog_" so
# that pack tables can't collide with tables owned by other packs.
module Catalog
  # Returns the prefix Active Record puts in front of every table name in this
  # namespace.
  def self.table_name_prefix
    "catalog_"
  end
end
