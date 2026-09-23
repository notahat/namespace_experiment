module Catalog
  # A single book in the catalog, always attributed to one author.
  class Book < Record
    belongs_to :author

    validates :title, presence: true
  end
end
