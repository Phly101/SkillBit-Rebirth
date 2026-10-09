CREATE TABLE contests
(
    id                 UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    title              varchar(150) NOT NULL,
    starts_at          TIMESTAMPTZ  NOT NULL,
    ends_at            TIMESTAMPTZ  NOT NULL,
    results_applied_at TIMESTAMPTZ,
    created_at         TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_contest_time_window CHECK (ends_at > starts_at),
    CONSTRAINT chk_contest_results_timing CHECK (results_applied_at IS NULL OR results_applied_at >= ends_at)

);
CREATE INDEX idx_contests_starts_ends ON contests (starts_at, ends_at);
CREATE TABLE contest_entries
(
    id                UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    contest_id        UUID        NOT NULL REFERENCES contests (id) ON DELETE RESTRICT,
    user_id           UUID        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    enrolled_at       TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    final_rank        INT CHECK ( final_rank > 0 ),
    contest_points    INT,
    bonus             INT CHECK ( bonus >= 0 ),
    user_points_after INT CHECK ( user_points_after >= 0 ),
    badge_id_after          UUID REFERENCES badges (id),
    CONSTRAINT uk_contest_user_entry UNIQUE (contest_id, user_id),
    CONSTRAINT chk_contest_results_completeness CHECK (
        (final_rank IS NULL AND contest_points IS NULL AND bonus IS NULL AND user_points_after IS NULL AND
         badge_id_after IS NULL) OR
        (final_rank IS NOT NULL AND contest_points IS NOT NULL AND bonus IS NOT NULL AND
         user_points_after IS NOT NULL AND
         badge_id_after IS NOT NULL)
        ),
    CONSTRAINT chk_contest_bonus_eligibility CHECK (
        bonus IS NULL OR (final_rank <= 3 AND bonus >= 0) OR (final_rank > 3 AND bonus = 0)
        )
);
CREATE INDEX idx_contest_entries_user_id ON contest_entries (user_id);
CREATE INDEX idx_contest_entries_contest_rank ON contest_entries (contest_id, final_rank);
CREATE TABLE contest_questions
(
    contest_id     UUID NOT NULL REFERENCES contests (id) ON DELETE CASCADE,
    question_id    UUID NOT NULL REFERENCES questions (id) ON DELETE RESTRICT,
    sequence_order INT  NOT NULL CHECK (sequence_order >= 0),
    PRIMARY KEY (contest_id, question_id),
    CONSTRAINT uk_contest_questions_sequence UNIQUE (contest_id, sequence_order)
);
CREATE INDEX idx_contest_questions_question_id ON contest_questions (question_id);