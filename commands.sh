#!/bin/bash

apk --update add letsencrypt

if letsencrypt -n certonly --standalone --agree-tos --test-cert \
-m admin@tropicloud.net -d deepbeep.tropicloud.xyz;
then echo "Oh Yes :)"
else echo "Oh No :("
fi



sudo rm -rf /opt/submarine
docker ps -aq | xargs docker rm -f
# docker rmi submarine2_submarine
# docker-compose up

docker run -d -p 80:80 --name nginx -v /tmp/nginx:/etc/nginx/conf.d -t nginx
docker run -it --rm --name nginx-gen --volumes-from nginx \
-v /var/run/docker.sock:/tmp/docker.sock:ro \
-v /tmp/templates:/etc/docker-gen/templates \
-t docker-gen -config ${PWD}/etc/docker-gen.cfg

[[config]]
template = "/etc/docker-gen/templates/nginx.tmpl"
dest = "/etc/nginx/conf.d/default.conf"
watch = true
wait = "30s:40s"

[config.NotifyContainers]
nginx = 1  # 1 is a signal number to be sent; here SIGINT


curl --unix-socket /tmp/app.sock -X GET http:/docker/challenge.json?callback=?
