require 'redis'

REDIS_HOST = "localhost"
REDIS_PORT = 6379

def redis
    @connection ||= Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)
end
