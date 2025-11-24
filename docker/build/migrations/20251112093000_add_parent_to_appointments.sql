-- migrate:up

ALTER TABLE appointments
ADD COLUMN parent_appointment_id INTEGER NULL;

ALTER TABLE appointments
ADD CONSTRAINT fk_appointments_parent
FOREIGN KEY (parent_appointment_id)
REFERENCES appointments(id)
ON DELETE SET NULL;

CREATE INDEX idx_appointments_parent_id ON appointments(parent_appointment_id);

-- migrate:down

DROP INDEX IF EXISTS idx_appointments_parent_id;

ALTER TABLE appointments
DROP CONSTRAINT IF EXISTS fk_appointments_parent;

ALTER TABLE appointments
DROP COLUMN IF EXISTS parent_appointment_id;

