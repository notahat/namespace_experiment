# A report from before the application was split into packs. It's a plain Ruby
# object living in a pack that hasn't opted in to automatic namespacing, so
# it stays a top-level constant.
class LegacyReport
  attr_reader :title

  # Creates a report with the given title.
  def initialize(title)
    @title = title
  end
end
