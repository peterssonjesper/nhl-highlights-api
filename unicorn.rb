@dir = "/var/www/nhl.jpetersson.se/api"

worker_processes 8
working_directory @dir

timeout 30

listen "#{@dir}/tmp/sockets/.unicorn.sock", :backlog => 64
pid "#{@dir}/tmp/pids/unicorn.pid"

stderr_path "#{@dir}/log/unicorn.stderr.log"
stdout_path "#{@dir}/log/unicorn.stdout.log"
