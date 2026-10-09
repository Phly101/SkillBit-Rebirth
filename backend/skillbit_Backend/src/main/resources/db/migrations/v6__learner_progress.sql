CREATE TABLE enrollments
(
    id          UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    user_id     UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    course_id   UUID         NOT NULL REFERENCES courses (id) ON DELETE RESTRICT,
    enrolled_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    finished_at TIMESTAMPTZ,

    CONSTRAINT uk_user_course_enrollment UNIQUE (user_id, course_id)
);
CREATE INDEX idx_enrollments_course_id ON enrollments (course_id);

CREATE TABLE lesson_completions
(
    id          UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    user_id     UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    lesson_id   UUID         NOT NULL REFERENCES lessons (id) ON DELETE RESTRICT,
    finished_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_user_lesson_completion UNIQUE (user_id, lesson_id)
);
CREATE INDEX idx_lesson_completions_lesson_id ON lesson_completions (lesson_id);