require 'date'
require 'json'

class Api < Sinatra::Base

    IMAGE_BASE_URL = "http://nhl.cdnllnwnl.neulion.net/u/"
    DAYS_TO_SHOW = 7

    get '/games' do
        today = Date.today
        dates = {}
        ((today-DAYS_TO_SHOW+1)..today).each do |day|
            game_ids = get_game_ids_by_day(day)
            games = game_ids.map do |id|
                get_game(id)
            end
            dates[day.to_s] = games if games.length > 0
        end

        dates.to_json
    end

    get '/games/:team' do |team|
        game_ids = get_game_ids_by_team(team)
        games = game_ids.map do |id|
            get_game(id)
        end
        games.to_json
    end

    def get_game_ids_by_day(day)
        key = day.to_s
        ids = redis.lrange("date:#{key}:gameid", 0, -1)
        return [] if ids.nil?
        ids
    end

    def get_game_ids_by_team(team)
        ids = redis.lrange("team:#{team}:gameid", 0, -1)
        return [] if ids.nil?
        ids
    end

    def get_game(game_id)
        game_s = redis.get("gameid:#{game_id}:game")
        game = JSON::parse(game_s)
        parse_game(game)
    end

    def parse_game(game)
        begin
            date = Date.strptime(game['game-date'].first, '%m/%d/%Y').to_s
        rescue
            date = ""
        end
        {
            state: game['game-state'].first,
            date: date,
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

end
