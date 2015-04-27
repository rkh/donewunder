Sequel.migration do
  change do
    create_table :hooks do
      primary_key :id
      integer     :user_id, index: true
      integer     :wunderlist_webhook_id
      integer     :wunderlist_list_id
      varchar     :done_this_short_name
      varchar     :secret
      varchar     :prefix
      bool        :include_subtasks, default: false
    end
  end
end