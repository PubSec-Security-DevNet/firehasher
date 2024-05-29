FROM ubuntu:22.04

# Copyright (c) 2024 Cisco and/or its affiliates.
#
# This software is licensed to you under the terms of the Cisco Sample
# Code License, Version 1.1 (the "License"). You may obtain a copy of the
# License at
#
#			    https://developer.cisco.com/docs/licenses
#
# All use of the material herein must be in accordance with the terms of
# the License. All rights not expressly granted by the License are
# reserved. Unless required by applicable law or agreed to separately in
# writing, software distributed under the License is distributed on an "AS
# IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied.
#

LABEL version="1.0"
LABEL description="XDR Feed MD5 Service"
LABEL maintainer="nciesins@cisco.com"

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade \
    && apt-get install --no-install-recommends -y \
        python3 \
        pip \
        nginx \
        redis \
    && apt-get clean \
    && apt-get purge \
    && rm -rf /var/lib/apt/lists/* 

WORKDIR /app

COPY requirements.txt .
#COPY static ./static
#COPY templates ./templates
#COPY docker ./docker
COPY app.py .
COPY config.yaml .

RUN pip install --no-cache-dir -r requirements.txt && \
    mkdir data && \
    touch init.sh && \
    chmod 744 init.sh && \
    echo "#!/bin/sh" >> init.sh && \
    echo "NGINX_CONF='/etc/nginx/sites-available/xdrmd5.conf'" >> init.sh && \
    echo "echo \"server {\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"   listen 80;\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"   location / {\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"       proxy_pass http://127.0.0.1:8000;\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"       proxy_set_header Host \\\$host;\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"       proxy_set_header X-Real-IP \\\$remote_addr;\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"       proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"       proxy_set_header X-Forwarded-Proto \\\$scheme;\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"   }\" >> \$NGINX_CONF" >> init.sh && \
    echo "echo \"}\" >> \$NGINX_CONF" >> init.sh && \
    echo "rm /etc/nginx/sites-enabled/default" >> init.sh && \
    echo "ln -s /etc/nginx/sites-available/xdrmd5.conf /etc/nginx/sites-enabled/xdrmd5.conf" >> init.sh && \
    echo "ln -sf /dev/stdout /var/log/nginx/access.log" >> init.sh && \
    echo "ln -sf /dev/stderr /var/log/nginx/error.log" >> init.sh && \
    touch run.sh && \
    chmod 744 run.sh && \
    echo "#!/bin/sh" >> run.sh && \
    echo "./init.sh" >> run.sh && \
    echo "sed -i '/.\/init.sh/{N;d;}' ./run.sh" >> run.sh && \
    echo "nginx -g 'daemon off;' &" >> run.sh && \
    echo "echo madvise > /sys/kernel/mm/transparent_hugepage/enabled" >> run.sh && \
    echo "redis-server &" >> run.sh && \
    echo "gunicorn --preload --workers=4 --bind 0.0.0.0:8000 app:app" >> run.sh
    
EXPOSE 80

CMD ["./run.sh"]