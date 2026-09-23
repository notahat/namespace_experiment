module Warehouses
  # A single place where stock is kept. It's a plain Ruby object rather than a
  # database-backed model, since the pack exists to demonstrate namespacing.
  class Warehouse
    attr_reader :name

    # Creates a warehouse with the given name.
    def initialize(name)
      @name = name
    end
  end
end
