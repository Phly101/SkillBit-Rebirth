-- Marks which users are admins. An admin is a normal user account plus one row here,
-- so the same account can play the app and open the admin tools.
-- Promote = insert a row, demote = delete the row.

CREATE TABLE admins
(
    user_id    UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp()
);
