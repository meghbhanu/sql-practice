SELECT title, event_date 
FROM events 
WHERE status = 'SCHEDULED'
ORDER BY event_date;

SELECT title, ticket_price
FROM events
WHERE ticket_price > 40
ORDER BY ticket_price DESC;

SELECT category, COUNT(*)
FROM events
GROUP BY category
ORDER BY COUNT(*) DESC;

SELECT * FROM users
WHERE phone IS NULL; 

-- NULL means unknown, not a value. 
-- Any comparison with NULL evaluates to unknown rather than true, 
-- and WHERE only keeps rows where the condition is true, so phone = NULL matches nothing. 
-- I use IS NULL to test for it.

SELECT category, COUNT(*), ROUND(AVG(ticket_price), 2) AS avg_price
FROM events
GROUP BY category
HAVING COUNT(*) >= 3;

SELECT COUNT(*) AS all_users, COUNT(phone) AS with_phone, COUNT(referred_by) AS referred
FROM users;