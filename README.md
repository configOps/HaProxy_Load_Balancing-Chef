**HaProxy_Load_Balancing**
This project includes cookbooks and vagrantsetup. 

**Cookbooks** hold chef recipes configure_haproxy and configure_nginx which installs and configure load balance Haproxy (balancer) and nginx webservers (webserver1 ,webserver2). Nginx webservers hold 'Hello World' in its index.html. 

Example :

Consider ips for balancer, webserver1, webserver2 as follows :

     Balancer			172.28.128.32 
     webserver1    		172.28.128.33
     webserver2         172.28.128.34 
     
So, when we hit 172.28.128.32:80, it fetches response either from webserver1 or webserver2 . In this committed code, roundrobin approach is followed to balance the traffic .

In **Vagrantsetup** , vagrant files of chef-server, chef-workstation, nodes (balancer, webserver1, webserver2) are commited. You will need to download appropriate rpm from chef website to install chef setup on chef-server and chef-workstation.
Once chef-server and chef-workstation are up. SSl certificates are required to make chef-server and chef-workstation communicate.

Few useful commands need to be executed on chef-workstation : 

 - Creates trusted certificates to make communication happen in chef-server and chef-workstation
 
		> knife ssl fetch

- Once certificated are successfully setup , it should show chef-server hostname from chef-workstation 

		> knife client list 

- Place cookbooks folder in chef-workstation and upload cookbooks to server using  *knife cookbook upload --all*
- Create roles to manage all 3 nodes using
 
		> knife role create webservers

		> knife role create load_balancer

		> knife role  run_list set webservers 'recipe[configure_nginx]'

		> knife role  run_list set load_balancer 'recipe[configure_haproxy]'

- Assign roles to nodes

		> knife node run_list set balancer 'role[load_balancer]'

		> knife node run_list set webserver1 'role[webservers]'

		> knife node run_list set webserver2 'role[webservers]'

Once webserver1, webserver2, balancer are up , run *knife bootstrap nodeip -x username -P password --sudo --node-name* from chef-workstation. This command will install boot up nodes (balancer,webserver1,webserver2) with chef setup on its own.Then run *sudo chef-client* on all three nodes which will fetch runlists from roles and run appropriate recipes for a node.

**Using pre-built cookbooks** 

You can use prebuilt cookbooks instead of cookbooks provided here.
Fot that you need to install haproxy and nginx from chef-supermarket using following comands :

    knife cookbook site install haproxy
    knife  cookbook site install nginx

As per nginx documentation, nginx requires rsyslog 2.0.0 as one of its dependencies but by default nginx cookbook installs higher version of rsyslog. So, remove rsyslog cookbook and use following command :

    knife cookbook site install rsyslog 2.0.0
  And now upload both cookbooks using following command :

    knife cookbook upload --all --include-dependencies
 Overiding attributes of haproxy at run time :

    knife role edit load_balancer
    export EDITOR=vim

Above commands will open json for load_balancer role where we can set run_list for this role as *haproxy* cookbook and override attributes at run time.Set attributes as follows :


  

    {"name": "load_balancer",
      "description": "",
      "json_class": "Chef::Role",
      "default_attributes": {},
      "override_attributes": {
        "haproxy": {
          "enable_admin": false,
          "incoming_address": "*IP of load balancer*",
          "incoming_port": "80",
          "members": [
            {
              "hostname": "webserver1",
              "ipaddress": "IP if webserver1",
              "port": 80
            },
            {
              "hostname": "webserver2",
              "ipaddress": "IP of webserver2",
              "port": 80
            }
          ]
        }
      },
      "chef_type": "role",
      "run_list": [
        "recipe[haproxy]"
      ],
      "env_run_lists": {}}

For setting up virtual host with pre-built nginx cookbook, create a custom cookbook 'conf-nginx' with default recipe as follows :

    include_recipe 'nginx'
      template "#{node['nginx']['dir']}/sites-enabled/#{node[:conf_nginx][:var_sitename]}" do
            source "serverconfig.erb"
    end
    directory "#{node['nginx']['dir']}/#{node[:conf_nginx][:var_sitename]}"
    
    template "#{node['nginx']['dir']}/#{node[:conf_nginx][:var_sitename]}/index.html" do
           source 'htmlpage.erb'
    end
    
    service 'nginx' do
            action [:stop,:start]
    end
and having attributes 'var_sitename'. Create an attribute using `chef generate attribute var_sitename` in the 'conf_nginx' cookbook folder. The above command will create a directory 'attributes' and a file 'var_sitename' in  'conf_nginx' cookbook folder.Write `node['conf_nginx']['var_sitename']=''` in var_sitename file.This will set sitename to empty string. Place following server configuration in templates folder in file  serverconfig.erb 

     server {
    
            listen   80;
            server_name <%= node['conf_nginx']['var_sitename'] %>;
            access_log /var/log/nginx/<%= node['conf_nginx']['var_sitename'] %>.access.log;
            error_log /var/log/nginx/<%= node['conf_nginx']['var_sitename'] %>.error.log;
            location / {
    root   <%= node['nginx']['dir']%>/<%= node['conf_nginx']['var_sitename'] %>;
            index  index.html index.htm;
        }}


 and in htmlpage.erb file place this : `<http><h1>"hello world"<h1><http>`
Add `depends 'nginx'` in metadata.rb of 'conf_nginx' cookbook to state that your custom cookbook wants to include recipe from another cookbook.
Now, you are done with writing custom cookbook conf_nginx which will call prebuilt cookbook nginx.

Lets override attributes for webservers role `knife role edit webservers` as follows :

        {
      "name": "webservers",
      "description": "",
      "json_class": "Chef::Role",
      "default_attributes": {
    
      },
      "override_attributes": {
        "nginx": {
          "default_site_enabled": false // this attribute disables default page of nginx by altering nginx.conf 
        },
        "configure_nginx": {
          "var_sitename": "helloworld"
        }
      },
      "chef_type": "role",
      "run_list": [
        "recipe[conf_nginx]"
      ],
      "env_run_lists": {
    
      }
    }

Thats all !! :)
