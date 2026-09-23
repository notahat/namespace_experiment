module Catalog
  # A single book in the catalog, always attributed to one author.
  class Book < ApplicationRecord
    belongs_to :author

    validates :title, presence: true
  end
end
