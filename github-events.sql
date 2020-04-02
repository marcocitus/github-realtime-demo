DROP TABLE IF EXISTS github_events;

CREATE TABLE github_events (
    event_id bigserial,
    data jsonb
);

CREATE INDEX github_event_id ON github_events USING brin (event_id);

SELECT create_distributed_table('github_events', 'event_id');
