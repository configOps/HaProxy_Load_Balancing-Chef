#package 'nginx'

#template "/usr/share/nginx/html/index.html" do
#	source 'htmlpage.erb'
#end

#service 'nginx' do
#	action [:stop :start]
#end

package 'nginx'

sitename ="#{node[:nginepic][:var_sitename]}"
directorypath="/etc/nginx/#{sitename}"
htmlfilepath="#{directorypath}/index.html"
serverconfigpath="/etc/nginx/conf.d/#{sitename}.conf"

directory "#{directorypath}"

template "#{htmlfilepath}" do
	source 'htmlpage.erb'
end

template "#{serverconfigpath}" do
	source 'serverconfig.erb'
end
