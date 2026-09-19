-- =====================================================================
-- Flight Ticket Booking Management System
-- queries.sql
-- Reports: flight, passenger, seat availability, booking, cancellation,
-- revenue -- plus general query concepts (joins, subqueries, group by,
-- window functions, CTEs).
-- =====================================================================

USE flight_booking_system;

-- =====================================================================
-- 1. FLIGHT REPORTS
-- =====================================================================

-- 1a. All flights with source/destination city names
SELECT f.flight_id, f.flight_number,
       src.city AS source_city, dst.city AS destination_city,
       f.departure_time, f.arrival_time, f.flight_status,
       fn_flight_duration_minutes(f.flight_id) AS duration_minutes
FROM flights f
JOIN airports src ON src.airport_id = f.source_airport_id
JOIN airports dst ON dst.airport_id = f.destination_airport_id
ORDER BY f.departure_time;

-- 1b. Flights departing "today" onward, still scheduled
SELECT flight_number, departure_time, arrival_time
FROM flights
WHERE departure_time >= NOW() AND flight_status = 'Scheduled'
ORDER BY departure_time;

-- 1c. Number of flights per route
SELECT src.city AS source_city, dst.city AS destination_city, COUNT(*) AS num_flights
FROM flights f
JOIN airports src ON src.airport_id = f.source_airport_id
JOIN airports dst ON dst.airport_id = f.destination_airport_id
GROUP BY src.city, dst.city
ORDER BY num_flights DESC
LIMIT 20;

-- 1d. Flight status breakdown
SELECT flight_status, COUNT(*) AS total
FROM flights
GROUP BY flight_status;

-- =====================================================================
-- 2. PASSENGER (CUSTOMER) REPORTS
-- =====================================================================

-- 2a. Passenger booking history
SELECT c.customer_id, c.customer_name, c.email,
       b.booking_id, f.flight_number, b.booking_date, b.booking_status
FROM customers c
JOIN bookings b ON b.customer_id = c.customer_id
JOIN flights f  ON f.flight_id = b.flight_id
ORDER BY c.customer_id, b.booking_date;

-- 2b. Top 10 customers by number of confirmed bookings
SELECT c.customer_id, c.customer_name, COUNT(*) AS confirmed_bookings
FROM customers c
JOIN bookings b ON b.customer_id = c.customer_id
WHERE b.booking_status = 'Confirmed'
GROUP BY c.customer_id, c.customer_name
ORDER BY confirmed_bookings DESC
LIMIT 10;

-- 2c. Customers who have never booked a flight (LEFT JOIN + NULL check)
SELECT c.customer_id, c.customer_name
FROM customers c
LEFT JOIN bookings b ON b.customer_id = c.customer_id
WHERE b.booking_id IS NULL;

-- 2d. Top spending customers (subquery + join)
SELECT c.customer_id, c.customer_name, SUM(p.amount) AS total_spent
FROM customers c
JOIN bookings b ON b.customer_id = c.customer_id
JOIN payments p ON p.booking_id = b.booking_id AND p.payment_status = 'Completed'
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC
LIMIT 10;

-- =====================================================================
-- 3. SEAT AVAILABILITY REPORTS
-- =====================================================================

-- 3a. Seat availability per flight & class (via view)
SELECT * FROM vw_seat_availability ORDER BY flight_id, seat_class;

-- 3b. Flights that are fully booked
SELECT flight_id, flight_number,
       SUM(total_seats) AS total_seats,
       SUM(available_seats) AS available_seats
FROM vw_seat_availability
GROUP BY flight_id, flight_number
HAVING SUM(available_seats) = 0;

-- 3c. Available seats for a specific flight (parameterised example)
SELECT seat_id, seat_number, seat_class, seat_price
FROM seats
WHERE flight_id = 1 AND seat_status = 'Available'
ORDER BY seat_class, seat_number;

-- =====================================================================
-- 4. BOOKING REPORTS
-- =====================================================================

-- 4a. Full booking detail (via view)
SELECT * FROM vw_booking_details ORDER BY booking_id LIMIT 100;

-- 4b. Bookings made in the last 30 days (relative to latest booking date in data)
SELECT booking_id, customer_id, flight_id, booking_date, booking_status
FROM bookings
WHERE booking_date >= (SELECT DATE_SUB(MAX(booking_date), INTERVAL 30 DAY) FROM bookings)
ORDER BY booking_date DESC;

-- 4c. Booking status distribution
SELECT booking_status, COUNT(*) AS total, 
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM bookings), 2) AS pct
FROM bookings
GROUP BY booking_status;

-- 4d. Monthly booking trend (window function-friendly grouping)
SELECT DATE_FORMAT(booking_date, '%Y-%m') AS booking_month, COUNT(*) AS total_bookings
FROM bookings
GROUP BY booking_month
ORDER BY booking_month;

-- =====================================================================
-- 5. CANCELLATION REPORTS
-- =====================================================================

-- 5a. All cancelled bookings with refund info
SELECT b.booking_id, c.customer_name, f.flight_number, b.booking_date,
       p.amount AS refund_amount, p.payment_status
FROM bookings b
JOIN customers c ON c.customer_id = b.customer_id
JOIN flights f   ON f.flight_id = b.flight_id
LEFT JOIN payments p ON p.booking_id = b.booking_id
WHERE b.booking_status = 'Cancelled';

-- 5b. Cancellation rate per flight
SELECT f.flight_id, f.flight_number,
       COUNT(*) AS total_bookings,
       SUM(CASE WHEN b.booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancellations,
       ROUND(SUM(CASE WHEN b.booking_status = 'Cancelled' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS cancellation_pct
FROM flights f
JOIN bookings b ON b.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number
HAVING cancellations > 0
ORDER BY cancellation_pct DESC;

-- 5c. Total refunded amount
SELECT SUM(amount) AS total_refunded
FROM payments
WHERE payment_status = 'Refunded';

-- =====================================================================
-- 6. REVENUE REPORTS
-- =====================================================================

-- 6a. Total revenue per flight (via view)
SELECT * FROM vw_flight_revenue ORDER BY total_revenue DESC LIMIT 20;

-- 6b. Total revenue by seat class
SELECT s.seat_class, SUM(p.amount) AS revenue, COUNT(*) AS tickets_sold
FROM payments p
JOIN bookings b ON b.booking_id = p.booking_id
JOIN seats s ON s.seat_id = b.seat_id
WHERE p.payment_status = 'Completed'
GROUP BY s.seat_class
ORDER BY revenue DESC;

-- 6c. Monthly revenue trend
SELECT DATE_FORMAT(payment_date, '%Y-%m') AS revenue_month, SUM(amount) AS revenue
FROM payments
WHERE payment_status = 'Completed'
GROUP BY revenue_month
ORDER BY revenue_month;

-- 6d. Revenue by payment method
SELECT payment_method, COUNT(*) AS transactions, SUM(amount) AS total_amount
FROM payments
WHERE payment_status = 'Completed'
GROUP BY payment_method
ORDER BY total_amount DESC;

-- 6e. Top 5 revenue-generating routes (CTE)
WITH route_revenue AS (
    SELECT f.flight_id, src.city AS source_city, dst.city AS destination_city, p.amount
    FROM payments p
    JOIN bookings b ON b.booking_id = p.booking_id
    JOIN flights f  ON f.flight_id = b.flight_id
    JOIN airports src ON src.airport_id = f.source_airport_id
    JOIN airports dst ON dst.airport_id = f.destination_airport_id
    WHERE p.payment_status = 'Completed'
)
SELECT source_city, destination_city, SUM(amount) AS total_revenue
FROM route_revenue
GROUP BY source_city, destination_city
ORDER BY total_revenue DESC
LIMIT 5;

-- 6f. Running (cumulative) revenue by month using a window function
SELECT revenue_month, revenue,
       SUM(revenue) OVER (ORDER BY revenue_month) AS cumulative_revenue
FROM (
    SELECT DATE_FORMAT(payment_date, '%Y-%m') AS revenue_month, SUM(amount) AS revenue
    FROM payments
    WHERE payment_status = 'Completed'
    GROUP BY revenue_month
) monthly
ORDER BY revenue_month;

-- 6g. Rank customers by spend using RANK() window function
SELECT customer_id, customer_name, total_spent,
       RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
FROM (
    SELECT c.customer_id, c.customer_name, SUM(p.amount) AS total_spent
    FROM customers c
    JOIN bookings b ON b.customer_id = c.customer_id
    JOIN payments p ON p.booking_id = b.booking_id AND p.payment_status = 'Completed'
    GROUP BY c.customer_id, c.customer_name
) spend
LIMIT 20;

-- =====================================================================
-- 7. USING THE STORED PROCEDURES / FUNCTION (examples)
-- =====================================================================

-- Book a new ticket (will fail with a clean error if the seat is taken)
-- CALL sp_book_ticket(1001, 5, 12, 250, 6500.00, 'UPI');

-- Cancel an existing booking
-- CALL sp_cancel_booking(1001);

-- Get a single flight's duration in minutes
-- SELECT fn_flight_duration_minutes(1) AS duration_minutes;
