CREATE TABLE users
(
    id                UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    email             VARCHAR(256) NOT NULL,
    password_hash     VARCHAR(200),
    name              VARCHAR(50)  NOT NULL,
    avatar_url        VARCHAR(500),
    points            INT          NOT NULL DEFAULT 0
        CONSTRAINT chk_users_points_non_negative CHECK (points >= 0),
    badge_id          UUID         NOT NULL REFERENCES badges (id),
    is_supporter      BOOLEAN      NOT NULL DEFAULT FALSE,
    is_email_verified BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at        TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_users_email UNIQUE (email),
    CONSTRAINT chk_users_email_lowercase CHECK (email = LOWER(email))
);

CREATE TABLE social_identities
(
    id               UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    user_id          UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    provider         VARCHAR(50)  NOT NULL
        CONSTRAINT chk_social_identities_provider CHECK (provider IN ('GOOGLE', 'GITHUB', 'APPLE', 'DISCORD')),
    provider_user_id VARCHAR(256) NOT NULL,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),

    CONSTRAINT uk_social_provider_identity UNIQUE (provider, provider_user_id)
);
CREATE INDEX idx_social_identities_user_id ON social_identities (user_id);

CREATE TABLE refresh_tokens
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ  NOT NULL,
    is_revoked BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_refresh_tokens_token_hash UNIQUE (token_hash)
);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens (user_id);

CREATE TABLE otp_codes
(
    id             UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    user_id        UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    purpose        VARCHAR(50)  NOT NULL
        CONSTRAINT chk_otp_codes_purpose CHECK (purpose IN ('EMAIL_VERIFICATION', 'PASSWORD_RESET', 'EMAIL_CHANGE')),
    code_hash      VARCHAR(255) NOT NULL,
    new_email      VARCHAR(256),
    attempts_count INT          NOT NULL DEFAULT 0
        CONSTRAINT chk_otp_codes_attempts_non_negative CHECK (attempts_count >= 0),
    is_used        BOOLEAN      NOT NULL DEFAULT FALSE,
    expires_at     TIMESTAMPTZ  NOT NULL,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT chk_otp_codes_new_email CHECK (
        (purpose = 'EMAIL_CHANGE' AND new_email IS NOT NULL) OR
        (purpose != 'EMAIL_CHANGE' AND new_email IS NULL)
        )
);
CREATE INDEX idx_otp_codes_user_id ON otp_codes (user_id);
CREATE UNIQUE INDEX uk_otp_codes_active_user_purpose ON otp_codes (user_id, purpose) WHERE (is_used = FALSE);

CREATE TABLE password_reset_tokens
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    user_id    UUID         NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    is_used    BOOLEAN      NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMPTZ  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_password_reset_tokens_token_hash UNIQUE (token_hash)
);
CREATE INDEX idx_password_reset_tokens_user_id ON password_reset_tokens (user_id);