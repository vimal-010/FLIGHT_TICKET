# ✈️ Flight Ticket Booking Management System

A complete MySQL database project for managing customer registration, flight
search, route selection, seat selection, ticket booking, payment,
cancellation, and booking history — modeled after a real-world airline
reservation system.

## 📁 Repository Structure

```
.
├── csv/flight_booking_csv_files/   1000-row sample dataset for each table
│   ├── airports.csv
│   ├── customers.csv
│   ├── flights.csv
│   ├── seats.csv
│   ├── bookings.csv
│   └── payments.csv
├── Flight_Ticket_Booking_System_Questions.pdf   Project brief & report questions
├── create_tables.sql               Schema: tables, constraints, indexes,
│                                    views, stored procedures, triggers, function
├── load_data.sql                   LOAD DATA INFILE scripts for all 6 tables
├── queries.sql                     Flight / passenger / seat / booking /
│                                    cancellation / revenue reports
├── flight_booking_ER_diagram.png   Entity-relationship diagram
└── README.md
```

## 🗂️ Database Schema

| Table       | Purpose                                    | Key Columns |
|-------------|---------------------------------------------|-------------|
| `airports`  | Airport master data                         | `airport_id` PK |
| `customers` | Registered passengers                       | `customer_id` PK |
| `flights`   | Flight schedule & route                     | `flight_id` PK, FKs → `airports` |
| `seats`     | Seat inventory per flight                   | `seat_id` PK, FK → `flights` |
| `bookings`  | Ticket bookings                              | `booking_id` PK, FKs → `customers`, `flights`, `seats` |
| `payments`  | Payment transactions per booking            | `payment_id` PK, FK → `bookings` |

See `flight_booking_ER_diagram.png` for the full relationship diagram.

## 🔧 MySQL Concepts Used

- **DDL**: `CREATE DATABASE`, `CREATE TABLE`, `ENUM`, `AUTO_INCREMENT`-ready PKs
- **Constraints**: `PRIMARY KEY`, `FOREIGN KEY` (`ON UPDATE`/`ON DELETE`), `UNIQUE`, `CHECK`, `NOT NULL`, `DEFAULT`
- **Indexes**: composite and single-column indexes on frequently filtered/joined columns
- **Views**: `vw_booking_details`, `vw_seat_availability`, `vw_flight_revenue`
- **Stored Procedures**: `sp_book_ticket`, `sp_cancel_booking` (transactional, with `ROLLBACK`/`SIGNAL`)
- **Function**: `fn_flight_duration_minutes`
- **Triggers**: keep `seats.seat_status` in sync with booking/cancellation events
- **Queries**: multi-table `JOIN`s, subqueries, `GROUP BY`/`HAVING`, `CTE`s (`WITH`), window functions (`RANK()`, `SUM() OVER`)

## 🚀 How to Run

1. **Create the schema:**
   ```bash
   mysql -u root -p < create_tables.sql
   ```
2. **Load the data:**
   Open `load_data.sql` and replace `/path/to/csv/flight_booking_csv_files/`
   with the absolute path to the `csv/flight_booking_csv_files/` folder on
   your machine, then run:
   ```bash
   mysql -u root -p --local-infile=1 < load_data.sql
   ```
3. **Run the reports:**
   ```bash
   mysql -u root -p flight_booking_system < queries.sql
   ```

## 📊 Reports Covered

- **Flight reports** – schedules, routes, status breakdown, duration
- **Passenger reports** – booking history, top customers, inactive customers, top spenders
- **Seat availability reports** – per-flight/class availability, fully booked flights
- **Booking reports** – full booking detail, recent bookings, status distribution, monthly trend
- **Cancellation reports** – cancelled bookings & refunds, cancellation rate per flight
- **Revenue reports** – revenue per flight/class/route/payment method, monthly trend, cumulative revenue, customer spend ranking

## 📦 Dataset

Each table's CSV file contains **1000 synthetically generated rows** with
full referential integrity (every foreign key in `flights`, `seats`,
`bookings`, and `payments` resolves to a valid row in its parent table).
"# FLIGHT_TICKET" 
"# FLIGHT_TICKET" 
"# FLIGHT_TICKET_MANAGEMENT-" 
