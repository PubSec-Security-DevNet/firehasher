"""
@license

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
"""

"""
@author	Nick Ciesinski (nciesins@cisco.com)
"""

import yaml
import redis
import requests
import urllib3
import hashlib
import io

from flask import Flask,Response
from apscheduler.schedulers.background import BackgroundScheduler

with open('config.yaml', 'r') as f:
    config = yaml.safe_load(f)

if not config['ssl']['verify']:
    # Disable warning about SSL verify being disabled
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

schedulerInterval = 60

app = Flask(__name__)

def debug(message):
    if config['debug']['enabled']:
        print('DEBUG:',message)

def initRedis():
    redisConnection = redis.Redis(host='localhost', port=6379, db=0)
    return redisConnection

def setRedisKeypair(redisConnection,key,value):
    redisConnection.set(key,value)

def getRedisKeypair(redisConnection,key):
    return redisConnection.get(key)

def getMD5(url,name):
    try:
        response = requests.get(url,verify=config['ssl']['verify'],timeout=10)
    except requests.exceptions.Timeout:
        debug(f'{name} Connection Timeout')
        return None
    except requests.exceptions.ConnectionError:
        debug(f'{name} Connection Error')
        return None

    if response.status_code == 200:
        debug(f'{response.content} Connection Error')
        return hashlib.md5(response.content).hexdigest()

def updateHashes(redisConnection):
    for feed in config['feeds']:
        md5Value = getMD5(feed['url'],feed['name'])
        if md5Value:
            debug(f'{feed["name"]} md5: {md5Value}')
            setRedisKeypair(redisConnection,feed['name'],md5Value)

redisConnection = initRedis()
updateHashes(redisConnection)
scheduler = BackgroundScheduler()
scheduler.add_job(updateHashes, 'interval', seconds=schedulerInterval, args=[redisConnection,])
scheduler.start()

@app.route('/feed/<string:name>')
def feed(name):
    md5Value = getRedisKeypair(redisConnection,name)
    if md5Value:
        return md5Value
    else:
        return "Invalid Feed Name"

if __name__ == '__main__':

    app.run(debug=True,use_reloader=False)