require 'sinatra'

get '/' do
  'hi'
end

post '/input' do
  params.to_s
end
