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
-- so the left join silently behaves like an inner join.”

-- Plainfield Park Pavilion has no events