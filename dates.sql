\COPY (SELECT d::date, h FROM generate_series('2020-01-01', '2020-01-31', interval '1 day') d, generate_series(0, 23) h ORDER BY 1, 2) TO 'dates.txt'
