require 'sinatra'

get '/' do
  erb :index
end

post '/login' do
  params.to_s
end
