#
# Cookbook Name:: redis
# Recipe:: default
#
instances = node[:engineyard][:environment][:instances]
redis_instance = instances.find{|i| i[:role] == 'app_master'}
if redis_instance
  ip_address = `ping -c 1 #{redis_instance[:private_hostname]} | awk 'NR==1{gsub(/\\(|\\)/,"",$3); print $3}'`.chomp
else
  ip_address = '127.0.0.1'
end

if ['app_master'].include?(node[:instance_role])
  # sysctl "Enable Overcommit Memory" do
  #   variables 'vm.overcommit_memory' => 1
  # end

  enable_package "dev-db/redis" do
    version "2.4.6"
  end

  package "dev-db/redis" do
    version "2.4.6"
    action :upgrade
  end

  directory "#{node[:redis][:basedir]}" do
    owner 'redis'
    group 'redis'
    mode 0755
    recursive true
    action :create
  end

  template "/etc/redis.conf" do
    owner 'root'
    group 'root'
    mode 0644
    source "redis.conf.erb"
    variables({
      :bind => ip_address,
      :pidfile => node[:redis][:pidfile],
      :basedir => node[:redis][:basedir],
      :basename => node[:redis][:basename],
      :logfile => node[:redis][:logfile],
      :loglevel => node[:redis][:loglevel],
      :port  => node[:redis][:bindport],
      :unixsocket => node[:redis][:unixsocket],
      :saveperiod => node[:redis][:saveperiod],
      :timeout => node[:redis][:timeout],
      :databases => node[:redis][:databases],
      :rdbcompression => node[:redis][:rdbcompression],
    })
  end

  template "/data/monit.d/redis.monitrc" do
    owner 'root'
    group 'root'
    mode 0644
    source "redis.monitrc.erb"
    variables({
      :profile => '1',
      :configfile => '/etc/redis.conf',
      :pidfile => node[:redis][:pidfile],
      :logfile => node[:redis][:basename],
      :port => node[:redis][:bindport],
    })
  end

  execute "monit reload" do
    action :run
  end
end

is_solo = node[:instance_role] == 'solo'
if ['solo', 'app', 'app_master', 'util'].include?(node[:instance_role])
  node.engineyard.apps.each do |app|
    template "/data/#{app.name}/shared/config/redis.yml" do
      owner node[:owner_name]
      group node[:owner_name]
      mode 0660
      source "redis.yml.erb"
      backup 0
      variables(:yaml_file => {
        node.engineyard.environment.framework_env => {
        :hosts => is_solo ? "127.0.0.1:6379" : "#{ip_address}:6379" }})
    end
  end
end
