DROP TABLE IF EXISTS github_commits;
DROP TABLE IF EXISTS daily_github_commits;

CREATE TABLE github_commits (
    event_id bigint,
    repo_id bigint,
    repo_name text,
    pusher_login text,
    branch text,
    created_at timestamp with time zone,
    author_name text,
    sha text,
    message text,
    comment text
);

CREATE INDEX commit_event_id_idx ON github_commits USING brin (event_id);
CREATE INDEX commit_repo_name_idx ON github_commits USING btree (repo_name);
CREATE INDEX commit_repo_id_idx ON github_commits USING btree (repo_id);
CREATE INDEX commit_sha_idx ON github_commits USING btree (sha);
CREATE INDEX commit_created_at_idx ON github_commits USING brin (created_at);

CREATE TABLE daily_github_commits (
    repo_id bigint,
    repo_name text,
    day date,
    num_commits bigint,
    PRIMARY KEY (repo_id, day)
);

SELECT create_distributed_table('github_commits', 'repo_id', colocate_with := 'github_events');
SELECT create_distributed_table('daily_github_commits', 'repo_id', colocate_with := 'github_events');

INSERT INTO rollups VALUES ('github_commits', 'github_events', 'github_events_event_id_seq')
ON CONFLICT (name) DO UPDATE SET last_aggregated_id = 0;

CREATE OR REPLACE FUNCTION extract_commits(OUT start_id bigint, OUT end_id bigint)
 RETURNS record
 LANGUAGE plpgsql
AS $function$
BEGIN
    SELECT window_start, window_end INTO start_id, end_id
    FROM incremental_rollup_window('github_commits');

    IF start_id > end_id THEN RETURN; END IF;

    INSERT INTO
      github_commits (event_id, repo_id, repo_name, pusher_login, branch, created_at, author_name, sha, message)
    SELECT
      event_id,
      repo_id,
      repo_name,
      actor_login,
      branch,
      created_at,
      cmt->'author'->>'name' author_name,
      cmt->>'sha' sha,
      cmt->>'message' message
    FROM (
      SELECT
        event_id,
        repo_id,
        repo_name,
        actor_login,
        payload->>'ref' branch,
        created_at,
        jsonb_array_elements(payload->'commits') cmt
      FROM (
        SELECT 
          event_id,
          (data->'repo'->>'id')::bigint repo_id,
          (data->'repo'->>'name') repo_name,
          (data->>'created_at')::timestamptz created_at,
          (data->'actor'->>'login')::text actor_login,
          data->'payload' payload
        FROM
          github_events
        WHERE
          data->>'type' = 'PushEvent' AND event_id BETWEEN start_id AND end_id
      ) events
    ) commits;

    INSERT INTO
      daily_github_commits
    SELECT
      repo_id,
      min(repo_name),
      created_at::date,
      count(*)
    FROM
      github_commits
    WHERE
      event_id BETWEEN start_id AND end_id
    GROUP BY
      1, 3
    ON CONFLICT (repo_id, day) DO UPDATE SET
      num_commits = daily_github_commits.num_commits + EXCLUDED.num_commits,
      repo_name = EXCLUDED.repo_name;

END;
$function$;
