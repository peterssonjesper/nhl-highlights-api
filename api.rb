require 'sinatra'

class Api < Sinatra::Base

    set :views, "./views"

    get '/' do
        erb :index
    end

    run! if app_file == $0

end

require './redis_connection'
require './controllers/games'
