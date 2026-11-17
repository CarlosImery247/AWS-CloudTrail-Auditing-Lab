-- Replace the table name with your own (cloudtrail_logs_<your-bucket>)

-- 1. Peek at the data
SELECT *
FROM cloudtrail_logs_YOURBUCKET
LIMIT 5;

-- 2. Focus on the most useful columns
SELECT useridentity.userName, eventtime, eventsource, eventname, requestparameters
FROM cloudtrail_logs_YOURBUCKET
LIMIT 30;

-- 3. EC2 security-related events
SELECT useridentity.userName, eventtime, eventsource, eventname, requestparameters
FROM cloudtrail_logs_YOURBUCKET
WHERE eventsource = 'ec2.amazonaws.com'
  AND eventname LIKE '%Security%';

-- 4. Who was active in the last day, and doing what
SELECT DISTINCT useridentity.userName, eventName, eventSource
FROM cloudtrail_logs_YOURBUCKET
WHERE from_iso8601_timestamp(eventtime) > date_add('day', -1, now())
ORDER BY eventSource;
