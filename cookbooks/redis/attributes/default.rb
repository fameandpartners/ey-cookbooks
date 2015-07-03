default[:redis] = { 
  :version => "2.4.6", 
  :bindport => "6379", 
  :unixsocket => "/tmp/redis.sock", 
  :basename => "/var/lib/redis/dump.rdb", 
  :basedir => "/var/lib/redis/", 
  :pidfile => "/var/run/redis.pid", 
  :loglevel => "notice", 
  :logfile => "/var/log/redis.log", 
  :timeout => 300000, 
  :saveperiod => ["900 1", "300 10", "60 10000"], 
  :databases => 16, 
  :rdbcompression => "yes"
}
