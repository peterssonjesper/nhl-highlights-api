require 'bundler/setup'

require 'date'
require 'json'
require 'httpclient'
require 'xmlsimple'
require 'nokogiri'

require_relative 'redis_connection'

DAYS_TO_SYNC = 7
SCORES_BASE_URL = "http://www.nhl.com/ice/scores.htm"
GAME_DATA_BASE_URL = "http://video.nhl.com/videocenter/highlights"
VIDEO_BASE_URL = "http://video.nhl.com/videocenter/servlets/playlist"

def sync
    today = Date.today
    ((today-DAYS_TO_SYNC+1)..today).each do |day|
        begin
            games = sync_games(day)
        rescue
            puts "Failed to fetch games on #{day}"
        else
            games.each do |game|
                if !redis.exists(game_id_key(game))
                    redis.set(game_id_key(game), game.to_json)
                    redis.rpush(date_key(day), game_id(game))
                    redis.rpush(team_away_key(game), game_id(game))
                    redis.rpush(team_home_key(game), game_id(game))
                end
            end
        end
    end
end

def game_id(game)
    "#{game['season'].first},#{game['game-type'].first},#{game['game-number'].first}"
end

def game_id_key(game)
    "gameid:#{game_id(game)}:game"
end

def team_away_key(game)
    "team:#{game['away-team'].first['team-abbreviation'].first}:gameid"
end

def team_home_key(game)
    "team:#{game['home-team'].first['team-abbreviation'].first}:gameid"
end

def date_key(day)
    "date:#{day.to_s}:gameid"
end

def sync_games(day)
    game_ids = fetch_game_ids(day)
    fetch_games(game_ids)
end

def fetch_game_ids(day)
    puts "Fetch game IDs on #{day}"
    day_s = "#{day.month}/#{day.day}/#{day.year}"
    scores_html = http_client.get_content(SCORES_BASE_URL, { date: day_s})
    page = page = Nokogiri::HTML(scores_html)
    page.css('#scoresBody a[href *= "?hlg="]').map do |a|
        a.attributes['href'].value.match(/hlg=([0-9,]+)/)[1]
    end
end

def fetch_games(hlg_ids)
    hlg_ids.map do |id|
        game = fetch_game_data(id)
        game['video'] = fetch_video(game['video-extid'].first)
        game
    end
end

def fetch_game_data(hlg_id)
    puts "Fetch game for HLG id #{hlg_id}"
    season, type, number = hlg_id.split(',')
    game_data_xml = http_client.get_content(GAME_DATA_BASE_URL, {xml: 1, season: season, type: type, number: number})
    XmlSimple.xml_in(game_data_xml)
end

def fetch_video(video_id)
    puts "Fetch video #{video_id}"
    video_json = http_client.get_content(VIDEO_BASE_URL, {format: 'json', ids: video_id})
    JSON::parse(video_json).first
end

def http_client
    @client ||= HTTPClient.new
end

sync
