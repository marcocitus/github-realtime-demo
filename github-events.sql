DROP TABLE IF EXISTS github_events;

CREATE TABLE github_events (
    event_id bigserial,
    repo_id bigint,
    data jsonb
);

CREATE INDEX github_event_id ON github_events USING brin (event_id);

SET citus.shard_count TO 160;
SELECT create_distributed_table('github_events', 'repo_id');
