require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'sinatra/flash'
require 'data_mapper'
require 'dm-sqlite-adapter'
require 'warden'
require 'pry'
require 'tilt/erb'

require './model'

require 'pry'

class StatTracker < Sinatra::Application
  enable :sessions
  register Sinatra::Flash


  use Warden::Manager do |config|
    config.serialize_into_session{|user| user.id }
    config.serialize_from_session{|id| User.get(id)}
    config.scope_defaults :default,
    strategies: [:password],
    action: 'auth/unauthenticated'
    config.failure_app = StatTracker
  end

  Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end

  Warden::Strategies.add(:password) do
    def valid?
      params['user']['username'] && params['user']['password']
    end

    def authenticate!
      user = User.first(username: params['user']['username'])

      if user.nil?
        fail!("That username does not exist.")
      elsif user.authenticate(params['user']['password'])
        success!(user)
      else
        fail!("Couldn't log in.")
      end
    end
  end

  get '/' do
    erb :index
  end

  get '/auth/login' do
    erb :login
  end

  post '/auth/login' do
    env['warden'].authenticate!
    flash[:success] = env['warden'].message
    redirect '/dash'
  end

  get '/auth/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout
    flash[:success] = 'Logged out!'
    redirect '/'
  end

  post '/auth/unauthenticated' do
    session[:return_to] = env['warden.options'][:attempted_path]
    puts env['warden.options'][:attempted_path]
    flash[:error] = env['warden'].message || "Must log in."
    redirect '/auth/login'
  end

  get '/dash' do
    authorize!
    @current_user = env['warden'].user
    erb :dash
  end

  private

  def authorize!
    redirect '/' unless env['warden'].user
  end
end
