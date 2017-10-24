#!/bin/bash

export YEAR=`date +%Y`

# ELASTICSEARCH ACCOUNT
export USER1=""
export PASS1=""
export HOST1=""

# EXTRACT ALL PUBLIC ELASTIC REPOS
echo "$(date): Extracting relevant data..."
find data/*.json.gz -type f -print0 | xargs -0 -P 8 zgrep --no-filename ',"name":"elastic/' >> output.json
#find data/2016-*.json.gz -type f -print0 | parallel -j+1 zgrep --no-filename ',"name":"elastic/' >> output.json
mv -v data/*.json.gz data/done

if [ $(curl -XHEAD -u ${USER1}:${PASS1} -I ${HOST1}/_template/githubarchive --head | grep "404 Not Found" > /dev/null) ]; then
    echo "$(date): Putting template on ${HOST1}"
    curl -XPUT -u ${USER1}:${PASS1} ${HOST1}/_template/githubarchive -d @mapping.json
fi

# PUSH TO LOGSTASH
echo "$(date): Preparing indices for ingestion on ${HOST1}"

# PREPARE INGEST
curl -XPUT -u ${USER1}:${PASS1} "${HOST1}/githubarchive-*/_settings" -d '{
    "index" : {
        "refresh_interval" : "-1"
    }
}'

# PUSH TO LOGSTASH
lines=`wc -l output.json`
echo "$(date): output.json has ${lines} lines"
cat output.json | /usr/share/logstash/bin/logstash -f logstash.conf --path.settings /etc/logstash

# ARCHIVE OUTPUT FILE
today=`date +%Y-%m-%d.%H%M%S`
mv -v output.json output-archive-${today}.json
gzip output-archive-${today}.json

# FINALIZE INGEST AND MAPPING
echo "$(date): Merging segments on ${HOST1}"
curl -XPOST -u ${USER1}:${PASS1} "${HOST1}/githubarchive-*/_forcemerge?max_num_segments=1"

echo "$(date): Restoring index settings on ${HOST1}"
curl -XPUT -u ${USER1}:${PASS1} "${HOST1}/githubarchive-*/_settings" -d '{
    "index" : {
        "refresh_interval" : "30s"
    }
}'
echo 

echo "$(date): Finished"
exit 0
