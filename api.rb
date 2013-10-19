require 'sinatra'
require 'date'
require 'json'
require 'redis'
require 'httpclient'
require 'xmlsimple'

require 'pry'

IMAGE_BASE_URL = "http://nhl.cdnllnwnl.neulion.net/u/"

get '/games' do
    today = Date.today
    interval = 6
    dates = {}
    ((today-interval)..today).each do |day|
        begin
            games = get_games(day)
        rescue
            puts "Failed to fetch games on #{day}"
        else
            dates[day.to_s] = games.map { |g| parse_game(g) }
        end
    end
    dates.to_json
end

def get_games(day)
    day_s = "#{day.month}/#{day.day}/#{day.year}"

    cache_key = day.to_s
    games = redis.get(cache_key)

    if games.nil?
        game_ids = fetch_game_ids(day)
        puts "Game IDs:"
        puts game_ids.to_json
        games = fetch_games(game_ids)
        redis.set(cache_key, games.to_json)
    else
        games = JSON::parse(games)
    end
    games
end

def fetch_game_ids(day)
    puts "Fetch game IDs on #{day}"
    day_s = "#{day.month}/#{day.day}/#{day.year}"
    scores_base_url = "http://www.nhl.com/ice/scores.htm"
    scores_html = http_client.get_content(scores_base_url, { date: day_s})
    scores_html.scan(/hlg=([0-9,]+)/).map {|x| x.first }
end

def fetch_games(hlg_ids)
    response = []
    hlg_ids.each do |id|
        game = fetch_game_data(id)
        game['video'] = fetch_video(game['video-extid'].first)
        response << game
    end
    response
end

def fetch_game_data(hlg_id)
    puts "Fetch game for HLG id #{hlg_id}"
    season, type, number = hlg_id.split(',')
    puts "fetch game #{hlg_id}"
    game_data_base_url = "http://video.nhl.com/videocenter/highlights"
    game_data_xml = http_client.get_content(game_data_base_url, {xml: 1, season: season, type: type, number: number})
    XmlSimple.xml_in(game_data_xml)
end

def fetch_video(video_id)
    puts "Fetch video #{video_id}"
    video_base_url = "http://video.nhl.com/videocenter/servlets/playlist"
    video_json = http_client.get_content(video_base_url, {format: 'json', ids: video_id})
    JSON::parse(video_json).first
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
            images: {
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
    @connection ||= Redis.new(:host => "localhost", :port => 6379)
end

def http_client
    @client ||= HTTPClient.new
end
