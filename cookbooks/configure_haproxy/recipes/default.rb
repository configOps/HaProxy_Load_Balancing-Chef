package "haproxy"


template "/etc/haproxy/haproxy.cfg" do
  source "haproxy.cfg.erb"
end

service "haproxy" do
  action [:enable, :start]
end

