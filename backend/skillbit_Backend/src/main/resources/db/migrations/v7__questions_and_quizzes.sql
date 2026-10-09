CREATE TABLE questions
(
    id            UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    question_type VARCHAR(50) NOT NULL CHECK (question_type IN ('MULTIPLE_CHOICE', 'PARSONS')),
    difficulty    VARCHAR(50) NOT NULL CHECK (difficulty IN ('EASY', 'MEDIUM', 'HARD')),
    status        VARCHAR(50) NOT NULL CHECK (status IN ('DRAFT', 'REVIEWED', 'PUBLISHED', 'RETIRED')),
    pool          VARCHAR(50) NOT NULL CHECK (pool IN ('QUIZ', 'CONTEST')),
    lesson_id     UUID REFERENCES lessons (id) ON DELETE RESTRICT,
    prompt        TEXT        NOT NULL,
    explanation   TEXT,
    hint          TEXT,
    language      VARCHAR(50),
    source        VARCHAR(255),
    replaces_id   UUID REFERENCES questions (id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_question_pool_lesson CHECK (
        (pool = 'QUIZ' AND lesson_id IS NOT NULL) OR
        (pool = 'CONTEST' AND lesson_id IS NULL)
        )
);
CREATE INDEX idx_questions_pool_status_difficulty ON questions (pool, status, difficulty);
CREATE INDEX idx_questions_lesson_id ON questions (lesson_id);
CREATE INDEX idx_questions_replaces_id ON questions (replaces_id);

CREATE TABLE question_topics
(
    question_id UUID NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    topic_id    UUID NOT NULL REFERENCES topics (id) ON DELETE CASCADE,
    PRIMARY KEY (question_id, topic_id)
);
CREATE INDEX idx_question_topics_topic_id ON question_topics (topic_id);

CREATE TABLE question_options
(
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id    UUID    NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    content        TEXT    NOT NULL,
    is_correct     BOOLEAN NOT NULL DEFAULT FALSE,
    sequence_order INT     NOT NULL CHECK (sequence_order >= 0),
    CONSTRAINT uk_question_options_sequence UNIQUE (question_id, sequence_order),
    CONSTRAINT uk_question_options_id_question UNIQUE (id, question_id)
);

CREATE UNIQUE INDEX uk_question_options_single_correct
    ON question_options (question_id) WHERE (is_correct = TRUE);

CREATE TABLE parsons_blocks
(
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question_id      UUID NOT NULL REFERENCES questions (id) ON DELETE CASCADE,
    code             TEXT NOT NULL,
    indentation      INT  NOT NULL    DEFAULT 0 CHECK (indentation >= 0),
    correct_position INT CHECK (correct_position >= 0),
    sequence_order   INT  NOT NULL CHECK (sequence_order >= 0),
    CONSTRAINT uk_parsons_blocks_sequence UNIQUE (question_id, sequence_order),
    CONSTRAINT uk_parsons_blocks_id_question UNIQUE (id, question_id)
);
CREATE UNIQUE INDEX uk_parsons_blocks_correct_position
    ON parsons_blocks (question_id, correct_position) WHERE (correct_position IS NOT NULL);

CREATE TABLE quiz_questions
(
    quiz_id        UUID NOT NULL REFERENCES quizzes (id) ON DELETE CASCADE,
    question_id    UUID NOT NULL REFERENCES questions (id) ON DELETE RESTRICT,
    sequence_order INT  NOT NULL CHECK (sequence_order >= 0),
    PRIMARY KEY (quiz_id, question_id),
    CONSTRAINT uk_quiz_questions_sequence UNIQUE (quiz_id, sequence_order)
);
CREATE INDEX idx_quiz_questions_question_id ON quiz_questions (question_id);