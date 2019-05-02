#!/usr/bin/bash
num_processed=$(psql -tAX -c "SELECT end_id-start_id AS num_process FROM extract_commits()")

if [ "$num_processed" -lt 1 ] ; then
  sleep 1
else
  psql -tAX -c "INSERT INTO extract (events) VALUES ($num_processed)" >/dev/null
  ispeed=$(psql -tAX -c "SELECT CASE WHEN count(*) > 1 THEN pg_size_pretty((60*sum(events)/(extract(epoch from max(extract_time)-min(extract_time))))::bigint*(SELECT sum(size)/sum(events) FROM (SELECT * FROM ingest ORDER BY ingest_time DESC LIMIT 10) a)::bigint) ELSE '17GB' END FROM (SELECT * FROM extract WHERE extract_time >= now() - interval '20 minutes' ORDER BY extract_time DESC LIMIT 10) extracts;")
  echo "extract_commits() processed $num_processed events ($ispeed/minute)" 
fi
