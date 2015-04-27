require 'sinatra/base'

module DoneWunder
  class Server < Sinatra::Base
    extend DoneWunder

    set :views, File.expand_path('../../views', __dir__)

    def current_user
      @current_user ||= session[:user_id] ? User.find(id: session[:user_id]) : nil
    end

    def current_user=(user)
      session[:user_id] = user ? user.id : nil
      @current_user     = user
    end

    def wunderlist
      @wunderlist ||= settings.wunderlist
      @wunderlist = @wunderlist.with_token(current_user.wunderlist_token) if current_user and current_user.wunderlist_token
      @wunderlist
    end

    def done_this
      return unless current_user.done_this_token
      @done_this ||= DoneThis.new(current_user.done_this_token)
    end

    def wunderlist_name(hook)
      list = wunderlist.lists.detect { |l| l["id"] == hook.wunderlist_list_id }
      list ? list['title'] : "???"
    end

    def done_this_name(hook)
      team = done_this.teams.detect { |t| t["short_name"] == hook.done_this_short_name }
      team ? team['name'] : "???"
    end

    def csrf
      '<input type="hidden" name="authenticity_token" id="authenticity_token" value="%s">' % session[:csrf]
    end

    enable :sessions
    set :session_secret, wunderlist.client_secret

    get '/' do
      halt slim(:login)           unless current_user
      halt slim(:setup_done_this) unless done_this
      slim(:home)
    end

    get '/login' do
      session[:state] = SecureRandom.urlsafe_base64
      auth_endpoint   = wunderlist.auth_endpoint(redirect_uri: uri('/auth/wunderlist'), state: session[:state])
      redirect to(auth_endpoint)
    end

    get '/logout' do
      self.current_user = nil
      redirect to(?/)
    end

    get '/auth/wunderlist' do
      state, session[:state] = session[:state], nil
      halt 400, 'state mismatch' if state.nil? or state != params[:state]

      wunder_user           = wunderlist.auth(params[:code])
      user                  = User.find_or_create(wunderlist_id: wunder_user.user_id)
      user.wunderlist_token = wunder_user.access_token
      user.name             = wunder_user.name
      user.save if user.modified?

      self.current_user = user
      redirect to(?/)
    end

    post '/done' do
      halt 403, 'not logged in'  unless current_user
      halt 400, 'no token given' unless token = params[:done_this_token]
      done = DoneThis.new(token)

      if done.ok?
        current_user.done_this_token = token
        current_user.save
        redirect to(?/)
      else
        slim(:setup_done_this, locals: {
          message: "Unfortunately, that does not seem to be a valid iDoneThis token."
        })
      end
    end

    get '/done' do
      redirect to(?/)
    end

    post '/add' do
      halt 403, 'not logged in'            unless current_user
      halt 400, 'missing wunderlist param' unless list_id    = Integer(params[:wunderlist])
      halt 400, 'missing done_this  param' unless short_name = params[:done_this] and not short_name.empty?

      hook = Hook.create({
        user_id:              current_user.id,
        wunderlist_list_id:   list_id,
        done_this_short_name: short_name,
        secret:               SecureRandom.urlsafe_base64,
        include_subtasks:     !!params[:include_subtasks],
        prefix:               params[:prefix].to_s
      })

      begin
        wunderlist_hook            = wunderlist.create_webhook(list_id, uri("/hook/#{hook.id}/#{hook.secret}"))
        hook.wunderlist_webhook_id = wunderlist_hook['id']
      ensure
        hook.wunderlist_webhook_id ? hook.save : hook.delete
      end

      redirect to(?/)
    end

    post '/hook/:id/:secret' do
      status 204

      hook = Hook.find(id: Integer(params[:id]))
      reject "hook not found"       if hook.nil?
      reject "secret doesn't match" if hook.secret != params[:secret]

      @current_user = hook.user
      payload       = JSON.load(request.body)

      reject "operation is #{payload['operation']}, not update"                  unless payload['operation']           == 'update'
      reject "before[completed] is #{payload['before']['completed']}, not false" unless payload['before']['completed'] == false
      reject "after[completed] is #{payload['before']['completed']}, not true"   unless payload['after']['completed']  == true

      reject "missing subject"                                                           unless subject    = payload['subject']
      reject "failed to parse data[completed_at] (%p)" % payload['data']['completed_at'] unless done_date  = payload['data']['completed_at'][/\d{4}-\d{2}-\d{2}/]
      reject "does not contain after[title]"                                             unless title      = payload['after']['title']
      reject "iDoneThis short_name missing from database"                                unless short_name = hook.done_this_short_name

      reject "subject[type] is #{payload['type']}" unless subject['type'] == 'task' or (subject['type'] == 'subtask' and hook.include_subtasks)

      puts "posting to iDoneThis: #{title.inspect}"
      done_this.done "#{hook.prefix}#{title}", short_name, done_date,
        done_wunder: { hook_id: hook.id, user_id: hook.user_id, uri: uri(?/) },
        wunderlist:  payload

      nil
    end

    def reject(message)
      puts "rejecting hook: #{message}"
      halt
    end

    post '/delete' do
      halt 403, 'not logged in' unless current_user
      hooks = params[:hooks] ? params[:hooks].keys : []
      hooks.each do |hook_id|
        next unless hook = Hook.find(id: Integer(hook_id))
        next unless hook.user == current_user
        wunderlist.delete_webook(hook.wunderlist_webhook_id)
        hook.delete
      end
      redirect to(?/)
    end

    error Wunderlist::Error do |error|
      content_type :txt
      halt 500, "Error talking to Wunderlist: #{error.message}"
    end

    error DoneThis::Error do |error|
      content_type :txt
      halt 500, "Error talking to iDoneThis: #{error.message}"
    end
  end
end
