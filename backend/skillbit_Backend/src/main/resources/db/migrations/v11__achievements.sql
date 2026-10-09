CREATE TABLE achievements
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    slug       VARCHAR(100) NOT NULL,
    title      VARCHAR(100) NOT NULL,
    description TEXT        NOT NULL,
    icon       VARCHAR(500) NOT NULL,
    metric     VARCHAR(50)  NOT NULL,
    threshold  INT          NOT NULL
        CONSTRAINT chk_achievements_threshold_positive CHECK (threshold > 0),
    scope      VARCHAR(100),
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_achievements_slug UNIQUE (slug)
);

CREATE TABLE user_achievements
(
    user_id        UUID        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    achievement_id UUID        NOT NULL REFERENCES achievements (id) ON DELETE RESTRICT,
    earned_at      TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (user_id, achievement_id)
);
CREATE INDEX idx_user_achievements_achievement_id ON user_achievements (achievement_id);
