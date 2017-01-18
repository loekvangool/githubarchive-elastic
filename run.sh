#!/bin/sh

export YEAR=`date +%Y`

# ELASTICSEARCH ACCOUNT
export USER1=""
export PASS1=""
export HOST1=""

# EXTRACT ALL PUBLIC ELASTIC REPOS
echo "Extracting relevant data..."
find data/*.json.gz -type f -print0 | xargs -0 -P 8 zgrep --no-filename ',"name":"elastic/' >> output.json
#find data/2016-*.json.gz -type f -print0 | parallel -j+1 zgrep --no-filename ',"name":"elastic/' >> output.json
mv -v data/*.json.gz data/done

# (RE) INITIALIZE TEMPLATE

if [ $(curl -XHEAD -u ${USER1}:${PASS1} -I ${HOST1}/_template/githubarchive --head | grep "404 Not Found" > /dev/null) ]; then
    echo "Putting template on ${HOST1}"
    curl -XPUT -u ${USER1}:${PASS1} ${HOST1}/_template/githubarchive -d @mapping.json
fi

# PUSH TO LOGSTASH
echo "Push to Logstash"

# PREPARE INGEST
curl -XPUT -u ${USER1}:${PASS1} "${HOST1}/githubarchive-*/_settings" -d '{
    "index" : {
        "refresh_interval" : "-1"
    }
}'

# PUSH TO LOGSTASH
cat output.json | logstash -f logstash.conf
cat output.json | ../5.0.0/logstash-5.0.0/bin/logstash -f logstash5.conf

# ARCHIVE OUTPUT FILE
today=`date +%Y-%m-%d.%H%M%S`
mv -v output.json output-archive-${today}.json
gzip output-archive-${today}.json

# FINALIZE INGEST AND MAPPING
echo "Merging segments on ${HOST1}"
curl -XPOST -u ${USER1}:${PASS1} "${HOST1}/githubarchive-*/_forcemerge?max_num_segments=1"
curl -XPUT -u ${USER1}:${PASS1} "${HOST1}/githubarchive-*/_settings" -d '{
    "index" : {
        "refresh_interval" : "30s"
    }
}'
echo 

echo "Finished"
exit 0
