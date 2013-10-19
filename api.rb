require 'date'
require 'sinatra'
require 'json'
require 'redis'

IMAGE_BASE_URL = "http://nhl.cdnllnwnl.neulion.net/u/"
DAYS_TO_SHOW = 7

REDIS_HOST = "localhost"
REDIS_PORT = 6379

get '/' do
    erb :index
end

get '/games' do
    today = Date.today
    dates = {}
    ((today-DAYS_TO_SHOW+1)..today).each do |day|
        games = get_games(day)
        dates[day.to_s] = games.map { |g| parse_game(g) }
    end

    dates.to_json
end

def get_games(day)
    cache_key = day.to_s
    games = redis.get(cache_key)
    if games.nil?
        []
    else
        JSON::parse(games)
    end
end

def parse_game(game)
    {
        state: game['game-state'].first,
        away_team: parse_team(game['away-team'].first),
        home_team: parse_team(game['home-team'].first),
        goals: {
            away: game['away-team'].first['goals'].first,
            home: game['home-team'].first['goals'].first
        },
        highlights: {
            url: game['video']['publishPoint'],
            description: game['video']['description'],
            duration: game['video']['runtime'],
            snapshot: {
                small: "#{IMAGE_BASE_URL}#{game['video']['image']}",
                big: "#{IMAGE_BASE_URL}#{game['video']['bigImage']}"
            }
        }
    }
end

def parse_team(team)
    {
        name: team['name'].first,
        city: team['city'].first,
        short: team['team-abbreviation'].first,
        logo: {
            small: team['logo-25px'].first,
            big: team['logo-100px'].first
        }
    }
end

def redis
    @connection ||= Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)
end
