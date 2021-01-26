DROP TABLE IF EXISTS github_events, template_github_events;

CREATE TABLE github_events (
    batch_hour timestamptz,
    event_id bigserial,
    data jsonb
)
PARTITION BY RANGE (batch_hour);


SELECT create_distributed_table('github_events', 'event_id');

CREATE TABLE template_github_events (LIKE github_events);
CREATE INDEX github_event_id ON template_github_events USING brin (event_id);

TRUNCATE partman.part_config CASCADE;
SELECT partman.create_parent(
  p_parent_table := 'public.github_events',
  p_control := 'batch_hour',
  p_type := 'native',
  p_interval := '1 day',
  p_start_partition := '2021-01-01',
  p_template_table := 'public.template_github_events'
);
DROP TABLE github_events_default;
