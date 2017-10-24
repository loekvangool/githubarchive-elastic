# githubarchive-elastic
Put your GitHub data in the [Elastic Stack](https://www.elastic.co/products).

# Requirements:
- Linux/OSX
- cURL
- Logstash locally
- Elasticsearch, locally or in the [cloud](http://cloud.elastic.co)

# Get Started:
* Edit `logstash.conf` and `run.sh`. Fill in the Elasticsearch host, port, and optionally authentication details. In `run.sh`, also fill `PATTERN`, which describes which orgs/repos you want to store in Elasticsearch (there are examples)
* Run `./download.sh bulk` to download all GitHub archives of 2015-2017, and/or
* Run `./download.sh YYYY-MM-DD` to download all GitHub archives of a single day (you can use this for daily updates to an existing index)
* At any time, you can run `./run.sh` to find the GitHub org/repo you're interested in, and export that to Elasticsearch

Tested in OSX and on Elastic Cloud, on Elasticsearch, Logstash and Kibana 5.1-5.6, with [X-Pack Security](https://www.elastic.co/guide/en/x-pack/current/xpack-security.html) enabled.

## Automation
Run daily:
`0  5   *   *   *    cd ~/githubarchive-elastic; ./download.sh; ./run.sh;`

Or, run hourly:
`0  *   *   *   *    cd ~/githubarchive-elastic; ./download.sh; ./run.sh;`

Note that `download.php` will download yesterday's data once per day, so you'll have to make sure that yesterday's data is complete, AND allow some time for possible late delivery. 05:00 UTC is usually enough for that. If you want more certainty, rig `download.php` to process more data than just yesterday's, or run the cron more often. Existing data will not be re-downloaded so you're free to run it as often as you like. It also sets its Elasticsearch document `id` explicitly, overwriting existing records if they are ingested multiple times.
