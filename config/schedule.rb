set :output, 'log/cron.log'

every 1.minute do
  rake 'webnews:sync'
end

every 1.day do
  rake 'webnews:clean_unread'
end
