CREATE TABLE quiz_attempts
(
    id                     UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id                UUID        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    quiz_id                UUID        NOT NULL REFERENCES quizzes (id) ON DELETE RESTRICT,
    shuffle_seed           BIGINT      NOT NULL,
    start_time             TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    deadline               TIMESTAMPTZ NOT NULL
        CONSTRAINT chk_quiz_attempts_deadline_comes_after_start CHECK (deadline > start_time),
    close_time             TIMESTAMPTZ
        CONSTRAINT chk_quiz_attempts_close_comes_after_start CHECK (close_time > start_time),
    close_reason           VARCHAR(50)
        CONSTRAINT chk_quiz_attempts_close_reason CHECK (close_reason IN ('SUBMITTED', 'TIME_RAN_OUT')),
    number_correct         INT
        CONSTRAINT chk_quiz_attempts_correct_range CHECK (number_correct >= 0 AND number_correct <= total_questions_served),
    total_questions_served INT         NOT NULL
        CONSTRAINT chk_quiz_attempts_total_questions_positive CHECK (total_questions_served > 0),
    CONSTRAINT chk_quiz_attempts_in_progress CHECK (
        (close_time IS NULL AND close_reason IS NULL AND number_correct IS NULL) OR
        (close_time IS NOT NULL AND close_reason IS NOT NULL AND number_correct IS NOT NULL)),
    CONSTRAINT chk_quiz_attempts_time_ran_out_after_deadline
        CHECK (close_reason IS DISTINCT FROM 'TIME_RAN_OUT' OR close_time >= deadline)
);
CREATE INDEX idx_quiz_attempts_user_quiz ON quiz_attempts (user_id, quiz_id);
CREATE INDEX idx_quiz_attempts_open_deadline ON quiz_attempts (deadline) WHERE close_time IS NULL;
CREATE UNIQUE INDEX uk_quiz_attempts_one_open_per_user_quiz ON quiz_attempts (user_id, quiz_id) WHERE close_time IS NULL;


CREATE TABLE quiz_attempt_questions
(
    attempt_id     UUID NOT NULL REFERENCES quiz_attempts (id) ON DELETE CASCADE,
    question_id    UUID NOT NULL REFERENCES questions (id) ON DELETE RESTRICT,
    sequence_order INT  NOT NULL
        CONSTRAINT chk_quiz_attempt_questions_order_non_negative CHECK (sequence_order >= 0),
    is_correct     BOOLEAN,
    PRIMARY KEY (attempt_id, question_id),
    CONSTRAINT uk_quiz_attempt_questions_sequence UNIQUE (attempt_id, sequence_order)
);
CREATE INDEX idx_quiz_attempt_questions_question_id ON quiz_attempt_questions (question_id);

-- Multiple choice: the one option the user picked for a question.
CREATE TABLE quiz_attempt_option_answers
(
    attempt_id  UUID NOT NULL,
    question_id UUID NOT NULL,
    option_id   UUID NOT NULL,
    PRIMARY KEY (attempt_id, question_id),
    CONSTRAINT fk_quiz_option_answers_served_question
        FOREIGN KEY (attempt_id, question_id)
            REFERENCES quiz_attempt_questions (attempt_id, question_id) ON DELETE CASCADE,
    CONSTRAINT fk_quiz_option_answers_option
        FOREIGN KEY (option_id, question_id)
            REFERENCES question_options (id, question_id) ON DELETE RESTRICT
);

-- Parsons: the blocks the user arranged, one row per position (0, 1, 2...).
CREATE TABLE quiz_attempt_parsons_answers
(
    attempt_id  UUID NOT NULL,
    question_id UUID NOT NULL,
    position    INT  NOT NULL
        CONSTRAINT chk_quiz_parsons_answers_position CHECK (position >= 0),
    block_id    UUID NOT NULL,
    PRIMARY KEY (attempt_id, question_id, position),
    CONSTRAINT uk_quiz_parsons_answers_block UNIQUE (attempt_id, question_id, block_id),
    CONSTRAINT fk_quiz_parsons_answers_served_question
        FOREIGN KEY (attempt_id, question_id)
            REFERENCES quiz_attempt_questions (attempt_id, question_id) ON DELETE CASCADE,
    CONSTRAINT fk_quiz_parsons_answers_block
        FOREIGN KEY (block_id, question_id)
            REFERENCES parsons_blocks (id, question_id) ON DELETE RESTRICT
);


CREATE TABLE contest_attempts
(
    id                     UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    contest_id             UUID        NOT NULL,
    user_id                UUID        NOT NULL,
    shuffle_seed           BIGINT      NOT NULL,
    badge_tier_at_start    INT         NOT NULL
        CONSTRAINT chk_contest_attempts_tier_range CHECK (badge_tier_at_start BETWEEN 1 AND 5),
    start_time             TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    deadline               TIMESTAMPTZ NOT NULL
        CONSTRAINT chk_contest_attempts_deadline_comes_after_start CHECK (deadline > start_time),
    close_time             TIMESTAMPTZ
        CONSTRAINT chk_contest_attempts_close_comes_after_start CHECK (close_time > start_time),
    close_reason           VARCHAR(50)
        CONSTRAINT chk_contest_attempts_close_reason CHECK (close_reason IN ('SUBMITTED', 'TIME_RAN_OUT')),
    number_correct         INT
        CONSTRAINT chk_contest_attempts_correct_range CHECK (number_correct >= 0 AND number_correct <= total_questions_served),
    points                 INT,
    total_questions_served INT         NOT NULL
        CONSTRAINT chk_contest_attempts_total_questions_positive CHECK (total_questions_served > 0),
    CONSTRAINT fk_contest_attempts_entry
        FOREIGN KEY (contest_id, user_id)
            REFERENCES contest_entries (contest_id, user_id) ON DELETE RESTRICT,
    CONSTRAINT uk_contest_attempts_contest_user UNIQUE (contest_id, user_id),
    CONSTRAINT chk_contest_attempts_in_progress CHECK (
        (close_time IS NULL AND close_reason IS NULL AND number_correct IS NULL AND points IS NULL) OR
        (close_time IS NOT NULL AND close_reason IS NOT NULL AND number_correct IS NOT NULL AND points IS NOT NULL)),
    CONSTRAINT chk_contest_attempts_time_ran_out_after_deadline
        CHECK (close_reason IS DISTINCT FROM 'TIME_RAN_OUT' OR close_time >= deadline)
);
CREATE INDEX idx_contest_attempts_user_id ON contest_attempts (user_id);
CREATE INDEX idx_contest_attempts_open_deadline ON contest_attempts (deadline) WHERE close_time IS NULL;

CREATE TABLE contest_attempt_questions
(
    attempt_id     UUID NOT NULL REFERENCES contest_attempts (id) ON DELETE CASCADE,
    question_id    UUID NOT NULL REFERENCES questions (id) ON DELETE RESTRICT,
    sequence_order INT  NOT NULL
        CONSTRAINT chk_contest_attempt_questions_order_non_negative CHECK (sequence_order >= 0),
    is_correct     BOOLEAN,
    PRIMARY KEY (attempt_id, question_id),
    CONSTRAINT uk_contest_attempt_questions_sequence UNIQUE (attempt_id, sequence_order)
);
CREATE INDEX idx_contest_attempt_questions_question_id ON contest_attempt_questions (question_id);

CREATE TABLE contest_attempt_option_answers
(
    attempt_id  UUID NOT NULL,
    question_id UUID NOT NULL,
    option_id   UUID NOT NULL,
    PRIMARY KEY (attempt_id, question_id),
    CONSTRAINT fk_contest_option_answers_served_question
        FOREIGN KEY (attempt_id, question_id)
            REFERENCES contest_attempt_questions (attempt_id, question_id) ON DELETE CASCADE,
    CONSTRAINT fk_contest_option_answers_option
        FOREIGN KEY (option_id, question_id)
            REFERENCES question_options (id, question_id) ON DELETE RESTRICT
);

CREATE TABLE contest_attempt_parsons_answers
(
    attempt_id  UUID NOT NULL,
    question_id UUID NOT NULL,
    position    INT  NOT NULL
        CONSTRAINT chk_contest_parsons_answers_position CHECK (position >= 0),
    block_id    UUID NOT NULL,
    PRIMARY KEY (attempt_id, question_id, position),
    CONSTRAINT uk_contest_parsons_answers_block UNIQUE (attempt_id, question_id, block_id),
    CONSTRAINT fk_contest_parsons_answers_served_question
        FOREIGN KEY (attempt_id, question_id)
            REFERENCES contest_attempt_questions (attempt_id, question_id) ON DELETE CASCADE,
    CONSTRAINT fk_contest_parsons_answers_block
        FOREIGN KEY (block_id, question_id)
            REFERENCES parsons_blocks (id, question_id) ON DELETE RESTRICT
);



CREATE TABLE friendly_match_attempts
(
    id                     UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    match_id               UUID        NOT NULL REFERENCES friendly_matches (id) ON DELETE RESTRICT,
    user_id                UUID        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    shuffle_seed           BIGINT      NOT NULL,
    start_time             TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    deadline               TIMESTAMPTZ NOT NULL
        CONSTRAINT chk_friendly_match_attempts_deadline_comes_after_start CHECK (deadline > start_time),
    close_time             TIMESTAMPTZ
        CONSTRAINT chk_friendly_match_attempts_close_comes_after_start CHECK (close_time > start_time),
    close_reason           VARCHAR(50)
        CONSTRAINT chk_friendly_match_attempts_close_reason CHECK (close_reason IN ('SUBMITTED', 'TIME_RAN_OUT')),
    number_correct         INT
        CONSTRAINT chk_friendly_match_attempts_correct_range CHECK (number_correct >= 0 AND number_correct <= total_questions_served),
    total_questions_served INT         NOT NULL
        CONSTRAINT chk_friendly_match_attempts_total_questions_positive CHECK (total_questions_served > 0),
    CONSTRAINT uk_friendly_match_attempts_match_user UNIQUE (match_id, user_id),
    CONSTRAINT chk_friendly_match_attempts_in_progress CHECK (
        (close_time IS NULL AND close_reason IS NULL AND number_correct IS NULL) OR
        (close_time IS NOT NULL AND close_reason IS NOT NULL AND number_correct IS NOT NULL)),
    CONSTRAINT chk_friendly_match_attempts_time_ran_out_after_deadline
        CHECK (close_reason IS DISTINCT FROM 'TIME_RAN_OUT' OR close_time >= deadline)
);
CREATE INDEX idx_friendly_match_attempts_user_id ON friendly_match_attempts (user_id);
CREATE INDEX idx_friendly_match_attempts_open_deadline ON friendly_match_attempts (deadline) WHERE close_time IS NULL;

CREATE TABLE friendly_match_attempt_questions
(
    attempt_id     UUID NOT NULL REFERENCES friendly_match_attempts (id) ON DELETE CASCADE,
    question_id    UUID NOT NULL REFERENCES questions (id) ON DELETE RESTRICT,
    sequence_order INT  NOT NULL
        CONSTRAINT chk_friendly_match_attempt_questions_order_non_negative CHECK (sequence_order >= 0),
    is_correct     BOOLEAN,
    PRIMARY KEY (attempt_id, question_id),
    CONSTRAINT uk_friendly_match_attempt_questions_sequence UNIQUE (attempt_id, sequence_order)
);
CREATE INDEX idx_friendly_match_attempt_questions_question_id ON friendly_match_attempt_questions (question_id);

CREATE TABLE friendly_match_attempt_option_answers
(
    attempt_id  UUID NOT NULL,
    question_id UUID NOT NULL,
    option_id   UUID NOT NULL,
    PRIMARY KEY (attempt_id, question_id),
    CONSTRAINT fk_match_option_answers_served_question
        FOREIGN KEY (attempt_id, question_id)
            REFERENCES friendly_match_attempt_questions (attempt_id, question_id) ON DELETE CASCADE,
    CONSTRAINT fk_match_option_answers_option
        FOREIGN KEY (option_id, question_id)
            REFERENCES question_options (id, question_id) ON DELETE RESTRICT
);

CREATE TABLE friendly_match_attempt_parsons_answers
(
    attempt_id  UUID NOT NULL,
    question_id UUID NOT NULL,
    position    INT  NOT NULL
        CONSTRAINT chk_match_parsons_answers_position CHECK (position >= 0),
    block_id    UUID NOT NULL,
    PRIMARY KEY (attempt_id, question_id, position),
    CONSTRAINT uk_match_parsons_answers_block UNIQUE (attempt_id, question_id, block_id),
    CONSTRAINT fk_match_parsons_answers_served_question
        FOREIGN KEY (attempt_id, question_id)
            REFERENCES friendly_match_attempt_questions (attempt_id, question_id) ON DELETE CASCADE,
    CONSTRAINT fk_match_parsons_answers_block
        FOREIGN KEY (block_id, question_id)
            REFERENCES parsons_blocks (id, question_id) ON DELETE RESTRICT
);



CREATE TABLE points_ledger
(
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id      UUID        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    amount       INT         NOT NULL,
    points_after INT         NOT NULL
        CONSTRAINT chk_points_ledger_points_after_non_negative CHECK (points_after >= 0),
    reason       VARCHAR(50) NOT NULL
        CONSTRAINT chk_points_ledger_reason CHECK (reason IN ('COURSE_FINISHED', 'CONTEST_RESULT')),
    course_id    UUID REFERENCES courses (id) ON DELETE RESTRICT,
    contest_id   UUID REFERENCES contests (id) ON DELETE RESTRICT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_points_ledger_source CHECK (
        (reason = 'COURSE_FINISHED' AND course_id IS NOT NULL AND contest_id IS NULL) OR
        (reason = 'CONTEST_RESULT' AND contest_id IS NOT NULL AND course_id IS NULL))
);
-- The same source can never pay the same user twice.
CREATE UNIQUE INDEX uk_points_ledger_user_course ON points_ledger (user_id, course_id) WHERE course_id IS NOT NULL;
CREATE UNIQUE INDEX uk_points_ledger_user_contest ON points_ledger (user_id, contest_id) WHERE contest_id IS NOT NULL;
-- A user's history, newest first.
CREATE INDEX idx_points_ledger_user_created ON points_ledger (user_id, created_at);
