SELECT COUNT(*) 
FROM users u
JOIN bookings b ON b.user_id = u.user_id
JOIN events e ON b.event_id = e.event_id;

SELECT v.name, e.title
FROM venues v
JOIN events e ON e.venue_id = v.venue_id
ORDER BY v.venue_id;

-- using Left join ensures that we get all venues, even if they have no events. (16)
-- If we used an inner join, we would only get venues that have events. (15)

SELECT e.title,
       COUNT(b.booking_id) AS bookings,
       COALESCE(SUM(b.quantity), 0) AS tickets
FROM events e
LEFT JOIN bookings b ON b.event_id = e.event_id AND b.status = 'CONFIRMED'
GROUP BY e.event_id, e.title
ORDER BY e.event_id; 

-- SUM over zero rows is NULL; COALESCE turns it into 0.
-- In a LEFT JOIN, a condition on the right table belongs in ON.
-- Put it in WHERE and the unmatched rows, which have NULLs on the right, 
-- fail the condition and get filtered out, 
-- so the left join silently behaves like an inner join.

-- Plainfield Park Pavilion has no events

SELECT u.full_name, u.email 
FROM users u
LEFT JOIN bookings b ON b.user_id = u.user_id
WHERE b.booking_id IS NULL;

SELECT u.full_name, u.email
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM bookings b
    WHERE b.user_id = u.user_id
);

SELECT u.full_name, u.email, r.full_name AS referred_by 
FROM users u
LEFT JOIN users r ON r.user_id = u.referred_by;

SELECT r.full_name AS referrer, COUNT(*) AS users_referred
FROM users u
LEFT JOIN users r ON r.user_id = u.referred_by
WHERE u.referred_by IS NOT NULL
GROUP BY u.referred_by, r.full_name
ORDER BY users_referred DESC;

SELECT full_name FROM users
WHERE user_id NOT IN (SELECT referred_by FROM users);
-- This query returns the users who have not referred anyone.
-- returns 0 because if the list contains NULL, the NOT IN condition evaluates to UNKNOWN for all rows, and no rows are returned.

WITH booking_totals AS (
    SELECT event_id, SUM(quantity) AS total_tickets
    FROM bookings
    WHERE status = 'CONFIRMED'
    GROUP BY event_id
),
review_totals AS (
    SELECT event_id, COUNT(*) AS total_reviews
    FROM reviews
    GROUP BY event_id
)
SELECT e.title,
       COALESCE(bt.total_tickets, 0) AS total_tickets,
       COALESCE(rt.total_reviews, 0) AS total_reviews
FROM events e
LEFT JOIN booking_totals bt ON bt.event_id = e.event_id
LEFT JOIN review_totals rt ON rt.event_id = e.event_id
ORDER BY e.title;

SELECT e.title, b.status, COUNT(r.review_id) AS total_reviews, SUM(b.quantity) AS total_tickets
FROM bookings b
JOIN events e ON e.event_id = b.event_id
JOIN reviews r ON r.event_id = e.event_id
WHERE b.status = 'CONFIRMED'
GROUP BY e.title, b.status;

SELECT e.title, SUM(b.quantity) AS total_tickets
FROM bookings b
JOIN events e ON e.event_id = b.event_id
WHERE e.title = 'Rock the Dome'
  AND b.status = 'CONFIRMED'
GROUP BY e.title;

-- the join result has one row per
-- booking-review pair, not one row per event

-- ===== Day 2 additions: paste each block next to the matching query in day2.sql =====

-- 1) LEFT JOIN venues (put this right after your INNER JOIN venues/events query)
SELECT v.name, e.title
FROM venues v
LEFT JOIN events e ON e.venue_id = v.venue_id
ORDER BY v.venue_id;
-- 16 rows: Plainfield Park Pavilion appears once with a NULL title.
-- The INNER JOIN version returns 15 rows because that venue has no events to match.


-- 2) Anti-join: which version to use
-- I would use NOT EXISTS. It reads like the question ("users for whom no booking exists"),
-- and it stays correct if NULLs are involved. LEFT JOIN ... IS NULL gives the same 4 rows,
-- but only works if I test a column that can never be NULL in a real match (b.booking_id).
-- Neither query has an ORDER BY, so the row order can differ between them.


-- 3) Referrer count: why WHERE u.referred_by IS NOT NULL is safe
-- Users with no referrer have referred_by = NULL, so they would form a NULL group
-- that is not a real referrer. Filtering them out removes it. After that filter every
-- remaining row has a match in r, so the LEFT JOIN behaves exactly like a plain JOIN.
-- Add a tie-break so equal counts have a stable order:
SELECT r.full_name AS referrer, COUNT(*) AS users_referred
FROM users u
JOIN users r ON r.user_id = u.referred_by
GROUP BY u.referred_by, r.full_name
ORDER BY users_referred DESC, r.full_name;


-- 4) NOT IN, fixed version (put this under the 0-row version)
SELECT full_name FROM users
WHERE user_id NOT IN (
    SELECT referred_by FROM users WHERE referred_by IS NOT NULL
);

-- 5) Fan-out trap: comments to put above/below your bad-join query
-- Prediction: 21 tickets for Rock the Dome (5 bookings repeated for each of 3 reviews).
-- Actual: 21 (bad join) vs 7 (bookings alone), and 15 "reviews" instead of 3.
-- Why: the grain. After joining bookings to reviews on event_id, the result has one row
-- per (booking, review) pair, not one row per event, so every booking is repeated once
-- per review and the totals are inflated. Fix: reduce each table to one row per event
-- (the two CTEs) and then join them.
-- Also: the bad query used an INNER JOIN, so events with no reviews disappeared (6 rows).

-- Grain, in one sentence: the grain of a result is what one row represents.