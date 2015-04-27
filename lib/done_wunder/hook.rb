module DoneWunder
  class Hook < Sequel::Model
    many_to_one :user
  end
end
