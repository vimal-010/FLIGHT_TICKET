DROP DATABASE IF EXISTS flight_booking_system;
CREATE DATABASE flight_booking_system
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE flight_booking_system;

-- ---------------------------------------------------------------------
-- 1. AIRPORTSflights
-- ---------------------------------------------------------------------
CREATE TABLE airports (
    airport_id   INT PRIMARY KEY,
    airport_name VARCHAR(150) NOT NULL,
    city         VARCHAR(100) NOT NULL,
    country      VARCHAR(100) NOT NULL,
    iata_code    CHAR(3) NOT NULL,
    CONSTRAINT uq_airports_iata UNIQUE (iata_code)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. CUSTOMERS
-- ---------------------------------------------------------------------
CREATE TABLE customers (
    customer_id   INT PRIMARY KEY,
    customer_name VARCHAR(150) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    email         VARCHAR(150) NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_customers_email UNIQUE (email),
    CONSTRAINT chk_customers_phone CHECK (CHAR_LENGTH(phone) >= 8)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. FLIGHTS
-- ---------------------------------------------------------------------
CREATE TABLE flights (
    flight_id             INT PRIMARY KEY,
    flight_number         VARCHAR(10) NOT NULL,
    source_airport_id     INT NOT NULL,
    destination_airport_id INT NOT NULL,
    departure_time        DATETIME NOT NULL,
    arrival_time           DATETIME NOT NULL,
    flight_status          ENUM('Scheduled','Delayed','Completed','Cancelled')
                            NOT NULL DEFAULT 'Scheduled',

    CONSTRAINT fk_flights_source
        FOREIGN KEY (source_airport_id) REFERENCES airports(airport_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT fk_flights_destination
        FOREIGN KEY (destination_airport_id) REFERENCES airports(airport_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT chk_flights_time CHECK (arrival_time > departure_time)
) ENGINE=InnoDB;

CREATE INDEX idx_flights_route ON flights(source_airport_id, destination_airport_id);
CREATE INDEX idx_flights_departure ON flights(departure_time);
CREATE INDEX idx_flights_status ON flights(flight_status);

-- Enforce source_airport_id <> destination_airport_id via triggers
DELIMITER $$

CREATE TRIGGER trg_flights_route_insert
BEFORE INSERT ON flights
FOR EACH ROW
BEGIN
    IF NEW.source_airport_id = NEW.destination_airport_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'source_airport_id and destination_airport_id must differ';
    END IF;
END$$

CREATE TRIGGER trg_flights_route_update
BEFORE UPDATE ON flights
FOR EACH ROW
BEGIN
    IF NEW.source_airport_id = NEW.destination_airport_id THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'source_airport_id and destination_airport_id must differ';
    END IF;
END$$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 4. SEATS
-- ---------------------------------------------------------------------
CREATE TABLE seats (
    seat_id     INT PRIMARY KEY,
    flight_id   INT NOT NULL,
    seat_number VARCHAR(5) NOT NULL,
    seat_class  ENUM('Economy','Premium Economy','Business','First')
                NOT NULL DEFAULT 'Economy',
    seat_price  DECIMAL(10,2) NOT NULL,
    seat_status ENUM('Available','Booked','Blocked') NOT NULL DEFAULT 'Available',
    CONSTRAINT fk_seats_flight
        FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT uq_seats_flight_seatnum UNIQUE (flight_id, seat_number),
    CONSTRAINT chk_seats_price CHECK (seat_price > 0)
) ENGINE=InnoDB;

CREATE INDEX idx_seats_flight_status ON seats(flight_id, seat_status);
CREATE INDEX idx_seats_class ON seats(seat_class);

-- ---------------------------------------------------------------------
-- 5. BOOKINGS
-- ---------------------------------------------------------------------
CREATE TABLE bookings (
    booking_id     INT PRIMARY KEY,
    customer_id    INT NOT NULL,
    flight_id      INT NOT NULL,
    seat_id        INT NOT NULL,
    booking_date   DATETIME NOT NULL,
    booking_status ENUM('Confirmed','Cancelled','Pending') NOT NULL DEFAULT 'Pending',
    CONSTRAINT fk_bookings_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_flight
        FOREIGN KEY (flight_id) REFERENCES flights(flight_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT fk_bookings_seat
        FOREIGN KEY (seat_id) REFERENCES seats(seat_id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
    CONSTRAINT uq_bookings_seat UNIQUE (seat_id)
) ENGINE=InnoDB;

CREATE INDEX idx_bookings_customer ON bookings(customer_id);
CREATE INDEX idx_bookings_flight ON bookings(flight_id);
CREATE INDEX idx_bookings_status ON bookings(booking_status);
CREATE INDEX idx_bookings_date ON bookings(booking_date);

-- ---------------------------------------------------------------------
-- 6. PAYMENTS
-- ---------------------------------------------------------------------
CREATE TABLE payments (
    payment_id     INT PRIMARY KEY,
    booking_id     INT NOT NULL,
    amount         DECIMAL(10,2) NOT NULL,
    payment_date   DATETIME NOT NULL,
    payment_status ENUM('Completed','Pending','Failed','Refunded') NOT NULL DEFAULT 'Pending',
    payment_method ENUM('Credit Card','Debit Card','UPI','Net Banking','Wallet') NOT NULL,
    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT uq_payments_booking UNIQUE (booking_id),
    CONSTRAINT chk_payments_amount CHECK (amount > 0)
) ENGINE=InnoDB; 

   
-- airports

CREATE INDEX idx_payments_status ON payments(payment_status);
CREATE INDEX idx_payments_date ON payments(payment_date);











-- =====================================================================
-- VIEWS  (used heavily by queries.sql / reports)
-- =====================================================================

-- Booking details combined across all related tables
CREATE OR REPLACE VIEW vw_booking_details AS
SELECT
    b.booking_id,
    c.customer_name,
    c.email,
    f.flight_number,
    f.departure_time,
    f.arrival_time,
    src.city   AS source_city,
    dst.city   AS destination_city,
    s.seat_number,
    s.seat_class,
    b.booking_status,
    p.amount,
    p.payment_status
FROM bookings b
JOIN customers c ON c.customer_id = b.customer_id
JOIN flights   f ON f.flight_id  = b.flight_id
JOIN airports  src ON src.airport_id = f.source_airport_id
JOIN airports  dst ON dst.airport_id = f.destination_airport_id
JOIN seats     s ON s.seat_id = b.seat_id
LEFT JOIN payments p ON p.booking_id = b.booking_id;

-- Seat availability per flight
CREATE OR REPLACE VIEW vw_seat_availability AS
SELECT
    f.flight_id,
    f.flight_number,
    s.seat_class,
    COUNT(*) AS total_seats,
    SUM(CASE WHEN s.seat_status = 'Available' THEN 1 ELSE 0 END) AS available_seats,
    SUM(CASE WHEN s.seat_status = 'Booked'    THEN 1 ELSE 0 END) AS booked_seats
FROM flights f
JOIN seats s ON s.flight_id = f.flight_id
GROUP BY f.flight_id, f.flight_number, s.seat_class;

-- Revenue per flight
CREATE OR REPLACE VIEW vw_flight_revenue AS
SELECT
    f.flight_id,
    f.flight_number,
    COUNT(p.payment_id) AS paid_bookings,
    SUM(p.amount)        AS total_revenue
FROM flights f
JOIN bookings b ON b.flight_id = f.flight_id
JOIN payments p ON p.booking_id = b.booking_id AND p.payment_status = 'Completed'
GROUP BY f.flight_id, f.flight_number;

-- =====================================================================
-- STORED PROCEDURES
-- =====================================================================
DELIMITER $$

-- Book a seat: creates booking + payment, and marks seat Booked (transactional)
CREATE PROCEDURE sp_book_ticket (
    IN  p_booking_id  INT,
    IN  p_customer_id INT,
    IN  p_flight_id   INT,
    IN  p_seat_id     INT,
    IN  p_amount      DECIMAL(10,2),
    IN  p_payment_method VARCHAR(20)
)
BEGIN
    DECLARE v_seat_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT seat_status INTO v_seat_status
    FROM seats WHERE seat_id = p_seat_id FOR UPDATE;

    IF v_seat_status <> 'Available' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Seat is not available for booking';
    END IF;

    INSERT INTO bookings (booking_id, customer_id, flight_id, seat_id, booking_date, booking_status)
    VALUES (p_booking_id, p_customer_id, p_flight_id, p_seat_id, NOW(), 'Confirmed');

    UPDATE seats SET seat_status = 'Booked' WHERE seat_id = p_seat_id;

    INSERT INTO payments (payment_id, booking_id, amount, payment_date, payment_status, payment_method)
    VALUES (p_booking_id, p_booking_id, p_amount, NOW(), 'Completed', p_payment_method);

    COMMIT;
END$$

-- Cancel a booking: updates booking/payment status and frees the seat
CREATE PROCEDURE sp_cancel_booking (IN p_booking_id INT)
BEGIN
    DECLARE v_seat_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    SELECT seat_id INTO v_seat_id FROM bookings WHERE booking_id = p_booking_id FOR UPDATE;

    UPDATE bookings SET booking_status = 'Cancelled' WHERE booking_id = p_booking_id;
    UPDATE seats SET seat_status = 'Available' WHERE seat_id = v_seat_id;
    UPDATE payments SET payment_status = 'Refunded' WHERE booking_id = p_booking_id;

    COMMIT;
END$$

DELIMITER ;

-- =====================================================================
-- FUNCTION
-- =====================================================================
DELIMITER $$

CREATE FUNCTION fn_flight_duration_minutes(p_flight_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_minutes INT;
    SELECT TIMESTAMPDIFF(MINUTE, departure_time, arrival_time)
      INTO v_minutes
      FROM flights WHERE flight_id = p_flight_id;
    RETURN v_minutes;
END$$

DELIMITER ;

-- =====================================================================
-- TRIGGERS
-- =====================================================================
DELIMITER $$

-- Keep seat_status in sync whenever a booking is inserted directly
CREATE TRIGGER trg_bookings_after_insert
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    IF NEW.booking_status = 'Confirmed' THEN
        UPDATE seats SET seat_status = 'Booked' WHERE seat_id = NEW.seat_id;
    END IF;
END$$

-- Keep seat_status in sync whenever a booking status changes (e.g. cancellation)
CREATE TRIGGER trg_bookings_after_update
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF NEW.booking_status = 'Cancelled' AND OLD.booking_status <> 'Cancelled' THEN
        UPDATE seats SET seat_status = 'Available' WHERE seat_id = NEW.seat_id;
    ELSEIF NEW.booking_status = 'Confirmed' AND OLD.booking_status <> 'Confirmed' THEN
        UPDATE seats SET seat_status = 'Booked' WHERE seat_id = NEW.seat_id;
    END IF;
END$$

DELIMITER ;

































