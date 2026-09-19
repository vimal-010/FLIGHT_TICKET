-- =====================================================================
-- Flight Ticket Booking Management System
-- load_data.sql
-- Bulk-loads the 1000-row CSV datasets in csv/flight_booking_csv_files/
-- into each table using LOAD DATA INFILE.
--
-- NOTES:
--  1. Run create_tables.sql first.
--  2. If your MySQL client blocks local file loading, either:
--       a) start the client with --local-infile=1, and enable the
--          server variable:  SET GLOBAL local_infile = 1;
--       b) or use LOAD DATA LOCAL INFILE (uncomment the LOCAL keyword
--          below) instead of LOAD DATA INFINE, and run this script from
--          the same machine where the CSV files reside.
--  3. Replace the path below with the absolute path to
--     csv/flight_booking_csv_files/ on your machine, e.g.
--     'C:/flight_project/csv/flight_booking_csv_files/'  (Windows) or
--     '/home/user/flight_project/csv/flight_booking_csv_files/' (Linux/Mac).
-- =====================================================================

USE flight_booking_system;

SET FOREIGN_KEY_CHECKS = 0;
SET GLOBAL local_infile = 1;

SET @csv_path = '/path/to/csv/flight_booking_csv_files/';

-- ---------------------------------------------------------------------
-- 1. AIRPORTS
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/csv/flight_booking_csv_files/airports.csv'
INTO TABLE airports
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(airport_id, airport_name, city, country, iata_code);

-- ---------------------------------------------------------------------
-- 2. CUSTOMERS
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/csv/flight_booking_csv_files/customers.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(customer_id, customer_name, phone, email);

-- ---------------------------------------------------------------------
-- 3. FLIGHTS
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/csv/flight_booking_csv_files/flights.csv'
INTO TABLE flights
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(flight_id, flight_number, source_airport_id, destination_airport_id,
 departure_time, arrival_time, flight_status);

-- ---------------------------------------------------------------------
-- 4. SEATS
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/csv/flight_booking_csv_files/seats.csv'
INTO TABLE seats
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(seat_id, flight_id, seat_number, seat_class, seat_price, seat_status);

-- ---------------------------------------------------------------------
-- 5. BOOKINGS
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/csv/flight_booking_csv_files/bookings.csv'
INTO TABLE bookings
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(booking_id, customer_id, flight_id, seat_id, booking_date, booking_status);

-- ---------------------------------------------------------------------
-- 6. PAYMENTS
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/csv/flight_booking_csv_files/payments.csv'
INTO TABLE payments
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(payment_id, booking_id, amount, payment_date, payment_status, payment_method);

SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------
SELECT 'airports'  AS table_name, COUNT(*) AS row_count FROM airports
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'flights',   COUNT(*) FROM flights
UNION ALL SELECT 'seats',     COUNT(*) FROM seats
UNION ALL SELECT 'bookings',  COUNT(*) FROM bookings
UNION ALL SELECT 'payments',  COUNT(*) FROM payments;
