Sequel.migration do
  change do
    create_table :users do
      primary_key :id
      integer     :wunderlist_id, index: true, unique: true
      varchar     :wunderlist_token
      varchar     :done_this_token
      varchar     :name
    end
  end
end