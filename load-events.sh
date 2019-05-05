#!/bin/sh

set -e

tmpfile=$(mktemp)
marker=loaded/$(basename $1)

mkdir -p loaded/
echo $* >> /tmp/files

if [ -f "$marker" ] ; then
  exit 0
fi

psql -X >$tmpfile <<EOF
\COPY github_events (repo_id, data) FROM PROGRAM 'gzip -dc $*'
EOF

if [ -s $tmpfile ]; then
  events=$(awk '{print $2}' $tmpfile)
  size=$(gzip -l $* | tail -n 1 | awk '{printf "%d",$2}')
  psql -tAX -c "INSERT INTO ingest (events, size) VALUES ($events, $size)" >/dev/null
  timestamp=$(date +"%F %T")  
  rate=$(psql -tAX -c " SELECT CASE WHEN count(*) > 10 THEN pg_size_pretty((((count(*)-1.0)/count(*))*60*sum(size)/(extract(epoch from (max(ingest_time)-min(ingest_time)))))::bigint) ELSE '17 GB' END FROM (SELECT * FROM ingest WHERE ingest_time >= now() - interval '5 minutes' ORDER BY ingest_time DESC LIMIT 20) ingests")
  echo "Ingested $events GitHub events ($rate/minute)"
  touch $marker
  rm $tmpfile
else
  rm $tmpfile
  exit 1
fi
