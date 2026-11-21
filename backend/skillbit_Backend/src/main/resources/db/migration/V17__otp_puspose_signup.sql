-- AI-written (Claude), reviewed by Basel.
-- The API calls the signup code purpose SIGNUP, but V3 only allowed EMAIL_VERIFICATION.
-- This makes the database use the same name as the API.

-- 1. Remove the old rule that only allows the old name.
ALTER TABLE otp_codes
    DROP CONSTRAINT chk_otp_codes_purpose;

-- 2. Rename the value in any rows that already exist.
UPDATE otp_codes
SET purpose = 'SIGNUP'
WHERE purpose = 'EMAIL_VERIFICATION';

-- 3. Add the rule back with the new name.
ALTER TABLE otp_codes
    ADD CONSTRAINT chk_otp_codes_purpose
        CHECK (purpose IN ('SIGNUP', 'PASSWORD_RESET', 'EMAIL_CHANGE'));
