# ======================================================================================================================
# Requires
# ======================================================================================================================

require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/json'

# Separete models loading
require_relative 'app/models/_init'

# ======================================================================================================================
# Controller
# ======================================================================================================================

class TabRec < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  # Configure logging
  configure :production, :development do
    enable :logging
    file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    file.sync = true
    use Rack::CommonLogger, file
  end

  # Redirect to Chrome store page
  get '/' do
    redirect 'https://chrome.google.com/webstore/detail/tabrec/namcfnibfapnjbnlfcijidilkgeaogde'
  end

  # --------------------------------------------------------------------------------------------------------------------
  # Users
  # --------------------------------------------------------------------------------------------------------------------

  # Show
  # -----------------------------------
  get '/users/:id' do
    user = User.find_by(id: params[:id])
    if user
      status 200
      json user
    else
      status 404
      json message: 'User not found'
    end
  end

  # Index
  # -----------------------------------
  get '/users' do
    json User.all
  end

  # Create
  # -----------------------------------
  post '/users' do
    user = User.new(params[:user])
    if user.save
      status 201
      json user
    else
      status 422
      json user.errors
    end
  end

  # Update
  # -----------------------------------
  put '/users/:id' do
    user = User.find(params[:id])

    new_experience = params.fetch('user').fetch('experience')
    user.experience = new_experience if new_experience

    new_rec_mode = params.fetch('user').fetch('rec_mode')
    user.rec_mode = new_rec_mode if new_rec_mode

    new_other_plugins = params.fetch('user').fetch('other_plugins', 'false') == 'true' ? true : false
    user.other_plugins = new_other_plugins

    if user.save
      status 200
      json user
    else
      status 422
      json user.errors
    end
  end

  # User browsing stats
  # -----------------------------------
  get '/stats/browsing/:id' do
    user = User.find(params[:id])
    bstats = {
      weekly: user.weekly_bstats,
      alltime: user.bstats
    }
    status 200
    json bstats
  end

  # --------------------------------------------------------------------------------------------------------------------
  # Usage Logs
  # --------------------------------------------------------------------------------------------------------------------

  # Bulk create
  # --------------------------------
  post '/logs/usage' do
    ulogs = params[:data]

    if ulogs
      ulogs.each do |ulog|
        # ulog is an array where first element is data index
        one_log = ulog[1]

        # Mandatory
        user_id = one_log.fetch 'user_id'
        tab_id = one_log.fetch 'tab_id'
        window_id = one_log.fetch 'window_id'
        timestamp = one_log.fetch 'timestamp'
        session_id = one_log.fetch 'session_id'
        event_id = Event.find_by(name: one_log.fetch('event')).id

        # Optional
        index_from = one_log.fetch('index_from', nil)
        index_to = one_log.fetch('index_to', nil)
        url = one_log.fetch('url', nil)
        domain = one_log.fetch('domain', nil)
        subdomain = one_log.fetch('subdomain', nil)
        path = one_log.fetch('path', nil)

        if UsageLog.create(user_id: user_id, tab_id: tab_id, event_id: event_id, window_id: window_id, url: url,
                        domain: domain, subdomain: subdomain, path: path, session_id: session_id,
                        index_from: index_from, index_to: index_to, timestamp: timestamp)
        else
          halt 422, 'Unprocessable data'
        end
      end

      status 201
      json message: 'Success'
    else
      halt 404, 'Usage log data missing.'
    end
  end

  # Index (last 300)
  # --------------------------------
  get '/logs/usage' do
    ul = UsageLog.order(created_at: :desc).limit(300)
    status 200
    json ul
  end

  # --------------------------------------------------------------------------------------------------------------------
  # Logs
  # --------------------------------------------------------------------------------------------------------------------

  # Index (last 300)
  # --------------------------------
  get '/logs/rec' do
    logs = Log.order(created_at: :desc).limit(300)
    status 200
    json logs
  end

  # Create
  # --------------------------------
  post '/logs/rec' do
    log_data = params[:log]

    # Mandatory attributes
    pattern_name = log_data[:pattern]
    resolution_name = log_data[:resolution]
    user_id = log_data[:user_id]

    # Creating log record
    pattern_id = Pattern.find_by(name: pattern_name).id
    resolution_id = Resolution.find_by(name: resolution_name).id
    log = Log.new(user_id: user_id, pattern_id: pattern_id, resolution_id: resolution_id)

    # Saving
    if log.save
      status 201
      json message: 'Success'
    else
      status 422
      json log.errors
    end
  end

  # Recommender stats
  # --------------------------------
  get '/stats/rec' do
    rec_stats = {
      provided: Log.count,
      accepted: Log.accepted.count + Log.automatic.count,
      rejected: Log.rejected.count,
      reverted: Log.reverted.count,
      yes: Log.yes.count,
      no: Log.no.count
    }
    status 200
    json rec_stats
  end

  # Recommender user stats
  # --------------------------------
  get '/stats/rec/:id' do
    uid = User.find(params[:id])
    rec_stats = {
      provided: Log.from_user(uid).count,
      accepted: Log.from_user(uid).accepted.count + Log.from_user(uid).automatic.count,
      rejected: Log.from_user(uid).rejected.count,
      reverted: Log.from_user(uid).reverted.count,
      yes: Log.from_user(uid).yes.count,
      no: Log.from_user(uid).no.count
    }
    status 200
    json rec_stats
  end

  # --------------------------------------------------------------------------------------------------------------------
  # Patterns
  # --------------------------------------------------------------------------------------------------------------------

  # Index
  get '/patterns' do
    patterns = Pattern.select(:id, :name, :sequence, :desc).joins(:advice).select('advices.name as advice_name')
    status 200
    json patterns
  end

  # --------------------------------------------------------------------------------------------------------------------
  # Advices
  # --------------------------------------------------------------------------------------------------------------------

  # Index
  get '/advices' do
    advices = Advice.select(:id, :name, :desc)
    status 200
    json advices
  end

  # --------------------------------------------------------------------------------------------------------------------
  # Resolutions
  # --------------------------------------------------------------------------------------------------------------------

  # Index
  get '/resolutions' do
    resolutions = Resolution.select(:id, :name, :desc)
    status 200
    json resolutions
  end

  # --------------------------------------------------------------------------------------------------------------------
  # Events
  # --------------------------------------------------------------------------------------------------------------------

  # Index
  get '/events' do
    events = Event.select(:id, :name, :desc)
    status 200
    json events
  end
end
