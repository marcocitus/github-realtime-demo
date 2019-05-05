#!/usr/bin/bash
op_id=$(psql -qtAX -c "INSERT INTO extract (start_time) VALUES (now()) RETURNING op_id") > /dev/null
num_processed=$(psql -tAX -c "SELECT end_id-start_id AS num_process FROM extract_commits()")

if [ "$num_processed" -eq "$num_processed" ] && [ "$num_processed" -gt 0 ] ; then
  psql -tAX -c "UPDATE extract SET events = $num_processed, end_time = now() WHERE op_id = $op_id" >/dev/null
  ispeed=$(psql -tAX -c "SELECT pg_size_pretty(60*sum(events)/(extract(epoch from sum(end_time-start_time)))::bigint*(SELECT sum(size)/sum(events) FROM (SELECT * FROM ingest ORDER BY ingest_time DESC LIMIT 10) a)::bigint) FROM (SELECT * FROM extract WHERE end_time >= now() - interval '10 minutes' ORDER BY end_time DESC LIMIT 5) extracts;")
  seconds=$(psql -tAX -c "SELECT extract(epoch from end_time - start_time)::int FROM extract WHERE op_id = $op_id;")
  echo "extract_commits() processed $num_processed events in $seconds seconds" 
else
  sleep 1
fi
