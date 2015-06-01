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
    @user = env['warden'].user
    erb :dash
  end

  get '/create_account' do
    bump_logged_in
    #TODO: could use a flash or whatever here to tell them they're already logged in
    erb :create_account
  end

  post '/create_account' do
    username = params[:username]
    password = params[:password]
    confirmation = params[:confirmation]

    if User.first(:username => username)
      #TODO: user exists, flash it
      redirect '/create_account'
    else
      if password == confirmation
        user = User.create(:username => username, :password => password)
        env['warden'].set_user(user)
        redirect '/dash'
      else
        #TODO: passwords didn't match, flash it
        redirect '/create_account'
      end
    end
  end

  get '/list' do
    bump_logged_out
    user = env['warden'].user
    @records = user.records
    erb :list
  end

  get '/new' do
    bump_logged_out
    erb :new
  end

  post '/new_record' do
    user = env['warden'].user
    record = user.records.first_or_new(:name => params['inputName'])
    unless record.id.nil?
      redirect :new
      #TODO: and flash about it
    end
    record.name = params['inputName']
    record.type = params['inputType']
    result = record.save
    case result
    when true
      redirect :dash
    when false
      redirect :new
      #TODO: and flash about it
    end
  end

  get '/view_record/:id' do
    bump_logged_out
    record = Record.get(params['id'])
    user = env['warden'].user
    if record
      if record.user_id == user.id
        @data = user.records.get(record.id).data
        @record_name = record.name
        @record_id = record.id
        erb :view
      else
        erb :list
        #TODO: flash that the record didn't belong to that user
      end
    else
      redirect :list
      #TODO: flash that we couldn't find that record
    end
  end

  post '/add_data' do
    user = env['warden'].user
    record = user.records.get(params['inputRecord'])
    if record && record.user_id == user.id
      datum = record.data.new
      datum.value = params['inputData']
      datum.date = Time.new
      datum.save
      redirect to("/view_record/" + record.id.to_s)
    else
      redirect :dash
      #TODO: Flash that user id didn't match record id
    end
  end

  private

  def logged_in?
    env['warden'].user
  end

  def logged_out?
    !logged_in?
  end

  #TODO: maybe we should define the flash here
  def bump_logged_in
    redirect '/dash' if logged_in?
  end

  def bump_logged_out
    redirect '/' if logged_out?
  end
end
