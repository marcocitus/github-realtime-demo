# github-realtime-demo

To use, ensure environment variables such as PGHOST, PGUSER, PGDATABASE, and PGPASSWORD are configured.

Preparation:

```bash
psql -f rollups.sql -f  github-events.sql -f github-commits.sql -f stats.sql
```

To load data for the first hour of 2020:
```bash
./load 2020-01-01 0
```

To transform the data into the github_commits and daily_github_commits tables:
```sql
SELECT * FROM extract_commits();
```
