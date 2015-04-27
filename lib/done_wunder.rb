require 'sequel'

module DoneWunder
  require 'done_wunder/wunderlist'
  require 'done_wunder/done_this'

  extend self

  @@database   = Sequel.connect(ENV.fetch('DATABASE_URL'))
  @@wunderlist = Wunderlist.new(ENV.fetch('WUNDERLIST_CLIENT_ID'), ENV.fetch('WUNDERLIST_CLIENT_SECRET'))

  def database
    @@database
  end

  def wunderlist
    @@wunderlist
  end

  require 'done_wunder/user'
  require 'done_wunder/hook'
  require 'done_wunder/server'
end
