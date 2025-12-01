-- DML.sql
-- Sample data for Fitness Club Management System

INSERT INTO members (full_name, email, date_of_birth, gender, phone)
VALUES
('Alice Johnson', 'alice@example.com', '1995-04-10', 'F', '555-1111'),
('Bob Smith', 'bob@example.com', '1990-07-21', 'M', '555-2222'),
('Mikhail Simanian', 'mikhail.simanian@my.senecacollege.ca', '2005-01-01', 'M', '555-3333');

INSERT INTO trainers (full_name, email, specialty, phone)
VALUES
('Coach Chris', 'chris.trainer@example.com', 'Strength', '555-4444'),
('Coach Dana', 'dana.trainer@example.com', 'Cardio', '555-5555');

INSERT INTO admin_staff (full_name, email, role_title)
VALUES
('Admin Alex', 'admin.alex@example.com', 'Manager');

INSERT INTO rooms (name, capacity, location)
VALUES
('Studio A', 20, '1st Floor'),
('Studio B', 15, '1st Floor'),
('PT Room 1', 1, '2nd Floor');

INSERT INTO trainer_availability (trainer_id, day_of_week, start_time, end_time)
VALUES
(1, 1, '09:00', '12:00'),
(1, 3, '14:00', '18:00'),
(2, 2, '10:00', '13:00');

INSERT INTO fitness_goals (member_id, goal_type, target_value, unit, description)
VALUES
(1, 'weight_loss', 60.0, 'kg', 'Lose weight to 60kg'),
(2, 'body_fat', 18.0, '%', 'Reduce body fat to 18%'),
(3, 'strength', NULL, NULL, 'Increase bench press max');

INSERT INTO health_metrics (member_id, height_cm, weight_kg, heart_rate_bpm, body_fat_percent)
VALUES
(1, 165.0, 70.0, 75, 25.0),
(1, 165.0, 68.5, 72, 24.0),
(2, 180.0, 85.0, 80, 22.0),
(3, 178.0, 82.0, 78, NULL);

INSERT INTO group_classes (title, trainer_id, room_id, start_time, end_time, capacity, base_price)
VALUES
('Morning Yoga', 2, 1, NOW() + INTERVAL '1 day', NOW() + INTERVAL '1 day 1 hour', 10, 15.00),
('HIIT Blast', 1, 2, NOW() + INTERVAL '2 days', NOW() + INTERVAL '2 days 1 hour', 15, 20.00);

INSERT INTO class_registrations (member_id, class_id)
VALUES
(1, 1);

INSERT INTO personal_training_sessions (member_id, trainer_id, room_id, start_time, end_time, status, price)
VALUES
(1, 1, 3, NOW() + INTERVAL '3 days', NOW() + INTERVAL '3 days 1 hour', 'scheduled', 50.00),
(2, 1, 3, NOW() + INTERVAL '4 days', NOW() + INTERVAL '4 days 1 hour', 'scheduled', 55.00);

INSERT INTO equipment (room_id, name, status)
VALUES
(1, 'Treadmill #1', 'operational'),
(1, 'Treadmill #2', 'out_of_order'),
(2, 'Rowing Machine #1', 'operational');

INSERT INTO equipment_maintenance (equipment_id, description, status)
VALUES
(2, 'Belt slipping, needs adjustment', 'open');

INSERT INTO invoices (member_id, total_amount, status)
VALUES
(1, 0, 'unpaid'),
(2, 0, 'unpaid');

INSERT INTO invoice_line_items (invoice_id, item_type, description, quantity, unit_price, line_total)
VALUES
(1, 'class', 'Morning Yoga class fee', 1, 15.00, 15.00),
(1, 'pt_session', 'PT Session with Coach Chris', 1, 50.00, 50.00),
(2, 'class', 'HIIT Blast class fee', 1, 20.00, 20.00);

UPDATE invoices
SET total_amount = (
    SELECT COALESCE(SUM(line_total), 0)
    FROM invoice_line_items ili
    WHERE ili.invoice_id = invoices.id
);
