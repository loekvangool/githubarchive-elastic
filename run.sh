#!/bin/sh

export YEAR=`date +%Y`

# REPOSITORY NAME PATTERN, EITHER ORG OR REPO LEVEL
# Examples:
#   "yahoo/"
#   "gztchan/awesome-design"
#   "nodejs/node"
export PATTERN="__SET_PATTERN__"

# PRIVATE ES CLOUD ACCOUNT
export USER=foo
export PASS=bar
export HOST=update_me

# EXTRACT MAIN ELASTIC REPOS
echo "Extracting relevant data..."
find data/*.json.gz -type f -print0 | xargs -0 -P 8 zgrep --no-filename ",\"name\":\"${PATTERN}" >> output.json
#find data/2016-*.json.gz -type f -print0 | parallel -j+1 zgrep --no-filename ',"name":"elastic/' >> output.json
mv -v data/*.json.gz data/done

# (RE) INITIALIZE TEMPLATE
# curl -XDELETE -u ${USER}:${PASS} ${HOST}/githubarchive-*

if [ $(curl -XHEAD -u ${USER}:${PASS} -I ${HOST}/_template/githubarchive --head | grep "404 Not Found" > /dev/null) ]; then
    echo "Putting template on ${HOST}"
    curl -XPUT -u ${USER}:${PASS} ${HOST}/_template/githubarchive -d @mapping.json
fi

# PUSH TO LOGSTASH
echo "Push to Logstash"

# PREPARE INGEST
curl -XPUT -u ${USER}:${PASS} "${HOST}/githubarchive-*/_settings" -d '{
    "index" : {
        "refresh_interval" : "-1"
    }
}'

# PUSH TO LOGSTASH
cat output.json | logstash -f logstash.conf

# ARCHIVE OUTPUT FILE
today=`date +%Y-%m-%d.%H%M%S`
mv -v output.json output-archive-${today}.json

# FINALIZE INGEST AND MAPPING
echo "Merging segments on ${HOST}"
curl -XPOST -u ${USER}:${PASS} "${HOST}/githubarchive-*/_forcemerge?max_num_segments=1"
curl -XPUT -u ${USER}:${PASS} "${HOST}/githubarchive-*/_settings" -d '{
    "index" : {
        "refresh_interval" : "1s"
    }
}'

echo "Finished"
exit 0
