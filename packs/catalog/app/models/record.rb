module Catalog
  # Abstract base class for every model in the Catalog pack. It exists so that
  # all of the pack's tables share the "catalog_" prefix, keeping them from
  # colliding with tables owned by other packs.
  class Record < ApplicationRecord
    self.abstract_class = true
    self.table_name_prefix = "catalog_"
  end
end
