CREATE TABLE friendships
(
    user_id_1  UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    user_id_2  UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    PRIMARY KEY (user_id_1, user_id_2),
    CONSTRAINT chk_friendships_not_with_self CHECK (user_id_2 != user_id_1),
    CONSTRAINT chk_friendships_ordered CHECK (user_id_1 < user_id_2)
);

CREATE INDEX idx_friendships_user_id_2 ON friendships (user_id_2);

CREATE TABLE friend_requests
(
    id          UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    sender_id   UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    receiver_id UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    status      VARCHAR(50) NOT NULL DEFAULT 'PENDING'
        CONSTRAINT chk_friend_requests_status CHECK (status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'CANCELED')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT chk_friend_request_not_from_self CHECK (sender_id != receiver_id)
);

CREATE INDEX idx_friend_requests_receiver_id ON friend_requests (receiver_id);
CREATE INDEX idx_friend_requests_sender_id ON friend_requests (sender_id);


CREATE UNIQUE INDEX uk_friend_requests_active_pair
    ON friend_requests (LEAST(sender_id, receiver_id), GREATEST(sender_id, receiver_id))
    WHERE (status = 'PENDING');


CREATE TABLE friendly_matches
(
    id                    UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    challenger_id         UUID        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    opponent_id           UUID        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    time_limit_seconds    INT         NOT NULL
        CONSTRAINT chk_friendly_matches_time_limit CHECK (time_limit_seconds > 0),
    status                VARCHAR(50) NOT NULL DEFAULT 'PENDING'
        CONSTRAINT chk_friendly_matches_status CHECK (
            status IN ('PENDING', 'ACCEPTED', 'DECLINED', 'EXPIRED', 'COMPLETED', 'CANCELED')
            ),


    winner_id             UUID REFERENCES users (id) ON DELETE RESTRICT,

    created_at            TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    invitation_expires_at TIMESTAMPTZ NOT NULL,
    accepted_at           TIMESTAMPTZ,
    play_deadline         TIMESTAMPTZ,
    completed_at          TIMESTAMPTZ,

    CONSTRAINT chk_friendly_matches_no_self CHECK (challenger_id != opponent_id),
    CONSTRAINT chk_friendly_matches_valid_winner CHECK (winner_id IS NULL OR winner_id IN (challenger_id, opponent_id)),
    CONSTRAINT chk_friendly_matches_deadlines CHECK (
        invitation_expires_at >= created_at AND
        (accepted_at IS NULL OR play_deadline >= accepted_at)
        ),


    CONSTRAINT chk_friendly_matches_acceptance_fields CHECK (
        (status IN ('PENDING', 'DECLINED') AND accepted_at IS NULL AND play_deadline IS NULL) OR
        (status IN ('ACCEPTED', 'COMPLETED') AND accepted_at IS NOT NULL AND play_deadline IS NOT NULL) OR
        (status IN ('EXPIRED', 'CANCELED') AND (accepted_at IS NULL) = (play_deadline IS NULL))
        ),


    CONSTRAINT chk_friendly_matches_results_completeness CHECK (
        (status = 'COMPLETED' AND completed_at IS NOT NULL AND completed_at >= accepted_at) OR
        (status != 'COMPLETED' AND winner_id IS NULL AND completed_at IS NULL)
        )
);

CREATE INDEX idx_friendly_matches_challenger_id ON friendly_matches (challenger_id);
CREATE INDEX idx_friendly_matches_opponent_id ON friendly_matches (opponent_id);
CREATE INDEX idx_friendly_matches_pending_expiration ON friendly_matches (invitation_expires_at) WHERE (status = 'PENDING');
CREATE INDEX idx_friendly_matches_accepted_deadline ON friendly_matches (play_deadline) WHERE (status = 'ACCEPTED');

CREATE TABLE friendly_match_topics
(
    match_id UUID NOT NULL REFERENCES friendly_matches (id) ON DELETE CASCADE,
    topic_id UUID NOT NULL REFERENCES topics (id) ON DELETE RESTRICT,
    PRIMARY KEY (match_id, topic_id)
);

CREATE INDEX idx_friendly_match_topics_topic_id ON friendly_match_topics (topic_id);


CREATE TABLE friendly_match_questions
(
    match_id       UUID NOT NULL REFERENCES friendly_matches (id) ON DELETE CASCADE,
    question_id    UUID NOT NULL REFERENCES questions (id) ON DELETE RESTRICT,
    sequence_order INT  NOT NULL
        CONSTRAINT chk_friendly_match_questions_seq_non_negative CHECK (sequence_order >= 0),

    PRIMARY KEY (match_id, question_id),
    CONSTRAINT uk_friendly_match_questions_sequence UNIQUE (match_id, sequence_order)
);

CREATE INDEX idx_friendly_match_questions_question_id ON friendly_match_questions (question_id);