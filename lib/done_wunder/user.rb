module DoneWunder
  class User < Sequel::Model
    one_to_many :hooks
  end
end