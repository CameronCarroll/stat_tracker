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
    bump_logged_in
    erb :index
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
    redirect '/'
  end

  get '/dash' do
    bump_logged_out
    @current_user = env['warden'].user
    erb :dash
  end

  get '/create_account' do
    bump_logged_in
    # could use a flash or whatever here to tell them they're already logged in
    erb :create_account
  end

  post '/create_account' do
    username = params[:username]
    password = params[:password]
    confirmation = params[:confirmation]

    if User.first(:username => username)
      # user exists, flash it
      redirect '/create_account'
    else
      if password == confirmation
        user = User.create(:username => username, :password => password)
        env['warden'].set_user(user)
        redirect '/dash'
      else
        # passwords didn't match, flash it
        redirect '/create_account'
      end
    end
  end

  get '/list' do
    bump_logged_out
    erb :list
  end

  get 'new' do
    bump_logged_out
    erb :new
  end

  private

  def logged_in?
    env['warden'].user
  end

  def logged_out?
    !logged_in?
  end

  # maybe we should define the flash here
  def bump_logged_in
    redirect '/dash' if logged_in?
  end

  def bump_logged_out
    redirect '/' if logged_out?
  end
end
