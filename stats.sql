BEGIN;
DROP TABLE IF EXISTS extract,ingest;
CREATE TABLE extract (op_id bigserial, start_time timestamptz default now(), end_time timestamptz, events bigint);
CREATE TABLE ingest (ingest_time timestamptz default now(), events bigint, size bigint);
END;
