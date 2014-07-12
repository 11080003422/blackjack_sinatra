require 'rubygems'
require 'sinatra'
require 'sinatra/reloader' if development?

set :sessions, true

get '/' do
  if session[:username].to_s == ''
    redirect '/set_name'
  else
    redirect '/game'
  end
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  session[:username] = params[:name]
  redirect '/'
end


