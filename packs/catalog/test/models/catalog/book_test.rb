require "test_helper"

module Catalog
  class BookTest < ActiveSupport::TestCase
    test "is invalid without a title" do
      book = Book.new(title: "", author: Author.new(name: "Octavia Butler"))

      assert_not book.valid?
    end

    test "is invalid without an author" do
      book = Book.new(title: "Kindred")

      assert_not book.valid?
    end

    test "is stored in a table prefixed with the pack name" do
      assert_equal "catalog_books", Book.table_name
    end

    test "belongs to an author in the same namespace" do
      author = Author.create!(name: "Octavia Butler")
      book = Book.create!(title: "Kindred", author: author)

      assert_equal author, book.reload.author
    end
  end
end
