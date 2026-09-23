require "test_helper"

module Catalog
  class AuthorTest < ActiveSupport::TestCase
    test "is invalid without a name" do
      author = Author.new(name: "")

      assert_not author.valid?
    end

    test "is stored in a table prefixed with the pack name" do
      assert_equal "catalog_authors", Author.table_name
    end

    test "destroys its books when destroyed" do
      author = Author.create!(name: "Ursula K. Le Guin")
      author.books.create!(title: "The Dispossessed")

      author.destroy

      assert_equal 0, Book.count
    end
  end
end
