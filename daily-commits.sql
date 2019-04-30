SELECT
  day, num_commits
FROM
  daily_github_commits
WHERE
  repo_id = 927442
ORDER BY day DESC LIMIT 7; -- pre-computed aggregates 
