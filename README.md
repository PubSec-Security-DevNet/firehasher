# Firehasher: Feed URL MD5 Hasher

## Description

When utilizing Cisco Secure Firewall alongside Threat Intelligence Feeds, an MD5 hash URL is required if the update interval is configured to less than 30 minutes—for example, at 5 or 15 minutes.

Some threat intelligence services, both public and private, may not offer an MD5 hash URL, which restricts the minimum update interval to 30 minutes. Firehasher addresses this limitation; it is a Docker container that initiates a simple process to poll feeds lacking an MD5 hash URL every 60 seconds and generates an MD5 hash from the obtained data. The container then makes this MD5 hash available through a URL, which can be integrated into the configuration of the Threat Intelligence Feed in Cisco Secure Firewall.

An example of a feed service that does not provide an MD5 hash URL is Cisco Extended Detection and Response (XDR).

## Installation

1. Copy the config.yaml.example file to config.yaml and add feeds you want Firehasher to make a MD5 hash URL for.  You can define any number of URLs.
2. Verify Docker is installed, install if not installed. `docker --version`
3. Build the Docker container. `docker build -t firehasher-image . --no-cache`
4. Run Docker container. `docker run -d --name firehasher -p 80:80/tcp firehasher-image`
    -  *Note, this will expose the Firehasher MD5 URL on port 80, if you need to change the port change the -p line.  Example to use port 8888: `-p 8888:80/tcp`*
5. Go into your Cisco Secure Firewall Threat Intelligence Feed configuration and add the MD5 URL. `http://<hostname running docker container>/feed/<feedname>`

Depending on the host OS and its settings you may see a performance warning in the docker logs regarding transparent hugepages being enabled when Docker starts redis.  
To solve this from the host that is hosting the Docker container run `echo madvise > /sys/kernel/mm/transparent_hugepage/enabled`.

## Author

- Nick Ciesinski

## License

This project is licensed to you under the terms of the [Apache License, Version 2.0](./LICENSE).

---

Copyright 2024 Cisco Systems, Inc. or its affiliates

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


 
