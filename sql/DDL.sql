-- DDL.sql
-- Fitness Club Management System - PostgreSQL schema
-- Student: Mikhail Simanian (101303853)

CREATE TABLE members (
    id              SERIAL PRIMARY KEY,
    full_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    date_of_birth   DATE,
    gender          TEXT,
    phone           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE trainers (
    id              SERIAL PRIMARY KEY,
    full_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    specialty       TEXT,
    phone           TEXT,
    hired_at        DATE DEFAULT CURRENT_DATE
);

CREATE TABLE admin_staff (
    id              SERIAL PRIMARY KEY,
    full_name       TEXT NOT NULL,
    email           TEXT NOT NULL UNIQUE,
    role_title      TEXT
);

CREATE TABLE fitness_goals (
    id              SERIAL PRIMARY KEY,
    member_id       INT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    goal_type       TEXT NOT NULL,
    target_value    NUMERIC(10,2),
    unit            TEXT,
    description     TEXT,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE health_metrics (
    id                  SERIAL PRIMARY KEY,
    member_id           INT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    recorded_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    height_cm           NUMERIC(5,2),
    weight_kg           NUMERIC(5,2),
    heart_rate_bpm      INT,
    body_fat_percent    NUMERIC(5,2)
);

CREATE TABLE rooms (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    capacity    INT NOT NULL CHECK (capacity > 0),
    location    TEXT
);

CREATE TABLE trainer_availability (
    id              SERIAL PRIMARY KEY,
    trainer_id      INT NOT NULL REFERENCES trainers(id) ON DELETE CASCADE,
    day_of_week     INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    CHECK (end_time > start_time)
);

CREATE TABLE group_classes (
    id              SERIAL PRIMARY KEY,
    title           TEXT NOT NULL,
    trainer_id      INT NOT NULL REFERENCES trainers(id),
    room_id         INT NOT NULL REFERENCES rooms(id),
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    capacity        INT NOT NULL CHECK (capacity > 0),
    base_price      NUMERIC(10,2) NOT NULL DEFAULT 0,
    CHECK (end_time > start_time)
);

CREATE TABLE class_registrations (
    id              SERIAL PRIMARY KEY,
    member_id       INT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    class_id        INT NOT NULL REFERENCES group_classes(id) ON DELETE CASCADE,
    registered_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (member_id, class_id)
);

CREATE TABLE personal_training_sessions (
    id              SERIAL PRIMARY KEY,
    member_id       INT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    trainer_id      INT NOT NULL REFERENCES trainers(id),
    room_id         INT NOT NULL REFERENCES rooms(id),
    start_time      TIMESTAMPTZ NOT NULL,
    end_time        TIMESTAMPTZ NOT NULL,
    status          TEXT NOT NULL DEFAULT 'scheduled',
    price           NUMERIC(10,2) NOT NULL,
    CHECK (end_time > start_time)
);

CREATE TABLE equipment (
    id              SERIAL PRIMARY KEY,
    room_id         INT REFERENCES rooms(id) ON DELETE SET NULL,
    name            TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'operational'
);

CREATE TABLE equipment_maintenance (
    id              SERIAL PRIMARY KEY,
    equipment_id    INT NOT NULL REFERENCES equipment(id) ON DELETE CASCADE,
    reported_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description     TEXT NOT NULL,
    status          TEXT NOT NULL DEFAULT 'open',
    resolved_at     TIMESTAMPTZ
);

CREATE TABLE invoices (
    id              SERIAL PRIMARY KEY,
    member_id       INT NOT NULL REFERENCES members(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    total_amount    NUMERIC(10,2) NOT NULL DEFAULT 0,
    status          TEXT NOT NULL DEFAULT 'unpaid'
);

CREATE TABLE invoice_line_items (
    id              SERIAL PRIMARY KEY,
    invoice_id      INT NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type       TEXT NOT NULL,
    description     TEXT NOT NULL,
    quantity        INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL,
    line_total      NUMERIC(10,2) NOT NULL
);

CREATE INDEX idx_pts_trainer_time
    ON personal_training_sessions (trainer_id, start_time);

CREATE OR REPLACE VIEW member_dashboard AS
SELECT
    m.id AS member_id,
    m.full_name,
    m.email,
    (SELECT hm.weight_kg
     FROM health_metrics hm
     WHERE hm.member_id = m.id
     ORDER BY hm.recorded_at DESC
     LIMIT 1) AS latest_weight_kg,
    (SELECT hm.heart_rate_bpm
     FROM health_metrics hm
     WHERE hm.member_id = m.id
     ORDER BY hm.recorded_at DESC
     LIMIT 1) AS latest_heart_rate_bpm,
    (SELECT COUNT(*)
     FROM fitness_goals fg
     WHERE fg.member_id = m.id
       AND fg.is_active = TRUE) AS active_goal_count,
    (SELECT COUNT(*)
     FROM class_registrations cr
     JOIN group_classes gc ON cr.class_id = gc.id
     WHERE cr.member_id = m.id
       AND gc.start_time < NOW()) AS past_class_count,
    (SELECT COUNT(*)
     FROM personal_training_sessions pts
     WHERE pts.member_id = m.id
       AND pts.status = 'scheduled'
       AND pts.start_time >= NOW()) AS upcoming_session_count
FROM members m;

CREATE OR REPLACE FUNCTION check_class_capacity()
RETURNS TRIGGER AS $$
DECLARE
    current_count INT;
    class_capacity INT;
BEGIN
    SELECT COUNT(*)
    INTO current_count
    FROM class_registrations
    WHERE class_id = NEW.class_id;

    SELECT capacity
    INTO class_capacity
    FROM group_classes
    WHERE id = NEW.class_id;

    IF current_count >= class_capacity THEN
        RAISE EXCEPTION 'Class is full. Capacity: %, Current: %', class_capacity, current_count;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_class_capacity
BEFORE INSERT ON class_registrations
FOR EACH ROW
EXECUTE FUNCTION check_class_capacity();
