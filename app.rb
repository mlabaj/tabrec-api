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

  get '/' do
    json message: 'Hello from TabRec API!'
  end

  get '/users/:id' do
    user = User.find(params[:id])
    json user
  end

  get '/events' do
    events = Event.all
    json events
  end

  post '/usage_logs' do
    data = params[:data]

    if data
      # Data format [0, {tab_id: 123, ... }, ...]
      data.each do |log|
        row = log[1]

        # Mandatory
        tab_id = row.fetch 'tab_id'
        window_id = row.fetch 'window_id'
        timestamp = row.fetch 'timestamp'
        event_id = Event.find_by(name: row.fetch('event')).id

        # Optional
        index_from = row.fetch('index_from', nil)
        index_to = row.fetch('index_to', nil)

        UsageLog.create(tab_id: tab_id, event_id: event_id, window_id: window_id,
                        index_from: index_from, index_to: index_to, timestamp: timestamp)
      end

      status 201
      json message: 'Created'
    else
      halt 400, 'Bad data format'
    end
  end

  get '/usage_logs/:id' do
    ul = UsageLog.find(params[:id])
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
  validates :rec_mode, presence: true, inclusion: { in: %w(interactive semi_interactive aggressive) }
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
