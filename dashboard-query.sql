\set repo_id random(1,10000000)
SELECT
  day, num_commits
FROM
  daily_github_commits
WHERE
  repo_id = :repo_id
ORDER BY 1 DESC LIMIT 7;
