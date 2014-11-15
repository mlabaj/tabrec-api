# ======================================================================================================================
# Requires
# ======================================================================================================================

require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/json'

# ======================================================================================================================
# Controllers
# ======================================================================================================================

class TabRec < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  # Home page
  get '/' do
    # Redirect to chrome web store
    json message: 'Hello from TabRec API!'
  end

  get '/users' do
    json User.all
  end

  get '/users/:id' do
    user = User.find(params[:id])
    json user
  end

  # Create user
  post '/users' do
    if user = User.create(params[:user])
      json user
    else
      json user.errors
    end
  end

  put '/users/:id' do
    user = User.find(params[:id])
    if user.update(params[:user])
      json user
    else
      json user.errors
    end
  end

  # Create usage log (logs)
  post '/usage_logs' do
    data = params[:data]

    if data
      # Data format [0, {tab_id: 123, ... }, ...]
      data.each do |log|
        row = log[1]

        # Mandatory
        user_id = row.fetch 'user_id'
        tab_id = row.fetch 'tab_id'
        window_id = row.fetch 'window_id'
        timestamp = row.fetch 'timestamp'
        event_id = Event.find_by(name: row.fetch('event')).id

        # Optional
        index_from = row.fetch('index_from', nil)
        index_to = row.fetch('index_to', nil)
        url = row.fetch('url', nil)

        UsageLog.create(user_id: user_id, tab_id: tab_id, event_id: event_id, window_id: window_id, url: url,
                        index_from: index_from, index_to: index_to, timestamp: timestamp)
      end

      status 201
      json message: 'Created'
    else
      halt 400, 'Bad data format'
    end
  end

  get '/usage_logs' do
    # Last 300 logs
    ul = UsageLog.order(created_at: :desc).limit(300)
    json ul
  end
end

# ======================================================================================================================
# Models
# ======================================================================================================================

##
# This table contains usage logs from tabrec extension.
# On specific :event, we log the time and other important attributes in that moment.
# The purpose is to get know how people use tabs and provide the best recomendation afterwards.
#
class UsageLog < ActiveRecord::Base
  belongs_to :user
  belongs_to :event
end

##
# This table contains recomendation logs from tabrec extension.
# On specific :event, we make an :advice and the :user can accept or reject it (:resolution).
#
class Log < ActiveRecord::Base
  belongs_to :user
  belongs_to :event
  belongs_to :advice
  belongs_to :resolution
end

class User < ActiveRecord::Base
  has_many :logs
  has_many :usage_logs

  validates :experience, presence: true, inclusion: { in: %w(beginner advanced expert) }
  validates :rec_mode, presence: true, inclusion: { in: %w(interactive semi-interactive aggressive) }
end

##
# The lowest level event, they are predefined (seeded).
# Example: tab_close, tab_open
#
class Event < ActiveRecord::Base
  has_many :logs
  has_many :usage_logs

  validates :name, presence: true
  validates :desc, presence: true
end

class Advice < ActiveRecord::Base
  has_many :logs

  validates :name, presence: true
  validates :desc, presence: true
end

class Resolution < ActiveRecord::Base
  has_many :logs

  validates :name, presence: true
  validates :desc, presence: true
end
