# githubarchive-elastic
Put your GitHub data in the [Elastic Stack](https://www.elastic.co/products).
# Get Started:
* Edit `logstash.conf` and `run.sh`. Fill in the Elasticsearch host, port, and optionally authentication details. In `run.sh`, also fill `PATTERN`, which describes which orgs/repos you want to store in Elasticsearch (there are examples)
* Run `./download.sh bulk` to download all GitHub archives of 2015 and 2016, and/or
* Run `./download.sh YYYY-MM-DD` to download all GitHub archives of a single day (you can use this for daily updates to an existing index)
* At any time, you can run `./run.sh` to find the GitHub org/repo you're interested in, and export that to Elasticsearch

Tested in OSX only, on Elasticsearch, Logstash and Kibana 5.1.x, with [X-Pack Security](https://www.elastic.co/guide/en/x-pack/current/xpack-security.html) enabled.
