CREATE TABLE payment_events
(
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    provider          VARCHAR(50)  NOT NULL
        CONSTRAINT chk_payment_events_provider CHECK (provider IN ('GOOGLE_PLAY')),
    provider_event_id VARCHAR(255) NOT NULL,
    event_type        VARCHAR(100) NOT NULL,
    user_id           UUID REFERENCES users (id) ON DELETE RESTRICT,
    product_id        VARCHAR(255),
    transaction_id    VARCHAR(255),
    payload           JSONB        NOT NULL,
    status            VARCHAR(50)  NOT NULL DEFAULT 'RECEIVED'
        CONSTRAINT chk_payment_events_status CHECK (status IN ('RECEIVED', 'PROCESSED', 'IGNORED', 'FAILED')),
    received_at       TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    processed_at      TIMESTAMPTZ,
    CONSTRAINT uk_payment_events_provider_event UNIQUE (provider, provider_event_id),
    CONSTRAINT chk_payment_events_processed_at CHECK ((status = 'RECEIVED') = (processed_at IS NULL))
);
CREATE INDEX idx_payment_events_user_id ON payment_events (user_id);
CREATE INDEX idx_payment_events_transaction_id ON payment_events (transaction_id) WHERE transaction_id IS NOT NULL;
CREATE INDEX idx_payment_events_unfinished ON payment_events (received_at) WHERE status IN ('RECEIVED', 'FAILED');



CREATE TABLE cosmetic_items
(
    id                     UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    slug                   VARCHAR(100) NOT NULL,
    title                  VARCHAR(100) NOT NULL,
    type                   VARCHAR(50)  NOT NULL
        CONSTRAINT chk_cosmetic_items_type CHECK (type IN ('AVATAR_FRAME', 'PROFILE_THEME', 'BADGE_SKIN', 'TITLE')),
    unlock_method          VARCHAR(50)  NOT NULL
        CONSTRAINT chk_cosmetic_items_unlock_method CHECK (unlock_method IN ('PURCHASE', 'DONATION', 'ALL_ACHIEVEMENTS')),
    asset_path             VARCHAR(500),
    google_play_product_id VARCHAR(255),
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_cosmetic_items_slug UNIQUE (slug),
    CONSTRAINT uk_cosmetic_items_google_play_product UNIQUE (google_play_product_id),
    CONSTRAINT uk_cosmetic_items_id_type UNIQUE (id, type),
    CONSTRAINT chk_cosmetic_items_purchase_product CHECK (
        (unlock_method = 'PURCHASE') = (google_play_product_id IS NOT NULL))
);

CREATE TABLE donation_products
(
    id                     UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    slug                   VARCHAR(100) NOT NULL,
    title                  VARCHAR(100) NOT NULL,
    google_play_product_id VARCHAR(255) NOT NULL,
    created_at             TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_donation_products_slug UNIQUE (slug),
    CONSTRAINT uk_donation_products_google_play_product UNIQUE (google_play_product_id)
);
CREATE TABLE user_cosmetics
(
    user_id          UUID        NOT NULL REFERENCES users (id) ON DELETE RESTRICT,
    cosmetic_id      UUID        NOT NULL,
    cosmetic_type    VARCHAR(50) NOT NULL,
    acquired_at      TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    payment_event_id BIGINT REFERENCES payment_events (id) ON DELETE RESTRICT,
    PRIMARY KEY (user_id, cosmetic_id),
    CONSTRAINT fk_user_cosmetics_item
        FOREIGN KEY (cosmetic_id, cosmetic_type)
            REFERENCES cosmetic_items (id, type) ON DELETE RESTRICT,
    CONSTRAINT uk_user_cosmetics_user_item_type UNIQUE (user_id, cosmetic_id, cosmetic_type)
);
CREATE INDEX idx_user_cosmetics_cosmetic_id ON user_cosmetics (cosmetic_id);
CREATE INDEX idx_user_cosmetics_payment_event_id ON user_cosmetics (payment_event_id) WHERE payment_event_id IS NOT NULL;


CREATE TABLE equipped_cosmetics
(
    user_id       UUID        NOT NULL,
    cosmetic_type VARCHAR(50) NOT NULL,
    cosmetic_id   UUID        NOT NULL,
    equipped_at   TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    PRIMARY KEY (user_id, cosmetic_type),
    CONSTRAINT fk_equipped_cosmetics_ownership
        FOREIGN KEY (user_id, cosmetic_id, cosmetic_type)
            REFERENCES user_cosmetics (user_id, cosmetic_id, cosmetic_type) ON DELETE CASCADE
);
