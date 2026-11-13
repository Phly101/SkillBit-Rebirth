-- Refresh token rotation with theft detection: each token remembers which token replaced it.
ALTER TABLE refresh_tokens
    ADD COLUMN replaced_by_id UUID;

ALTER TABLE refresh_tokens
    ADD CONSTRAINT fk_refresh_tokens_replaced_by
        FOREIGN KEY (replaced_by_id) REFERENCES refresh_tokens (id) ON DELETE SET NULL;

ALTER TABLE refresh_tokens
    ADD CONSTRAINT chk_refresh_tokens_not_self_replaced
        CHECK (replaced_by_id IS NULL OR replaced_by_id <> id);

CREATE INDEX idx_refresh_tokens_replaced_by_id ON refresh_tokens (replaced_by_id);
