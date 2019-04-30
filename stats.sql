CREATE TABLE extract (extract_time timestamptz, events bigint);
CREATE TABLE ingest (ingest_time timestamptz default now(), events bigint);
