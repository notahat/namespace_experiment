module Catalog
  # A person who wrote one or more books in the catalog. Deleting an author
  # deletes their books, since a book can't exist without an author.
  class Author < Record
    has_many :books, dependent: :destroy

    validates :name, presence: true
  end
end
