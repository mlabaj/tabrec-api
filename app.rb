require 'sinatra/base'
require 'sinatra/activerecord'
require 'sinatra/json'

class TabRec < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  get '/' do
    'Hello from TabRec API!'
  end

  get '/users/:id' do
    user = User.find(params[:id])
    json user
  end
end

class User < ActiveRecord::Base
  validates_presence_of :experience_level
end
