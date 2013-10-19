require 'date'
require 'json'
require 'redis'
require 'httpclient'
require 'xmlsimple'

DAYS_TO_SYNC = 7
SCORES_BASE_URL = "http://www.nhl.com/ice/scores.htm"
GAME_DATA_BASE_URL = "http://video.nhl.com/videocenter/highlights"
VIDEO_BASE_URL = "http://video.nhl.com/videocenter/servlets/playlist"

REDIS_HOST = "localhost"
REDIS_PORT = 6379

def sync
    today = Date.today
    ((today-DAYS_TO_SYNC+1)..today).each do |day|
        begin
            games = sync_games(day)
        rescue
            puts "Failed to fetch games on #{day}"
        else
            cache_key = day.to_s
            redis.set(cache_key, games.to_json)
        end
    end
end

def sync_games(day)
    game_ids = fetch_game_ids(day)
    fetch_games(game_ids)
end

def fetch_game_ids(day)
    puts "Fetch game IDs on #{day}"
    day_s = "#{day.month}/#{day.day}/#{day.year}"
    scores_html = http_client.get_content(SCORES_BASE_URL, { date: day_s})
    scores_html.scan(/hlg=([0-9,]+)/).map {|x| x.first }
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

def redis
    @connection ||= Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)
end

def http_client
    @client ||= HTTPClient.new
end

sync
