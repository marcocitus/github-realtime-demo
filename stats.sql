DROP TABLE IF EXISTS extract,ingest;
CREATE TABLE extract (extract_time timestamptz default now(), events bigint);
CREATE TABLE ingest (ingest_time timestamptz default now(), events bigint, size bigint);
