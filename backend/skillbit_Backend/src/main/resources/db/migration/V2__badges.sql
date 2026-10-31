CREATE TABLE badges
(
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name             VARCHAR(50)  NOT NULL,
    icon             VARCHAR(200) NOT NULL,
    promotion_points INT          NOT NULL CONSTRAINT chk_badges_promotion_points_non_negative CHECK (promotion_points >= 0),
    demotion_points  INT          NOT NULL CONSTRAINT chk_badges_demotion_points_non_negative CHECK (demotion_points >= 0),
    tier             INT          NOT NULL CONSTRAINT chk_badges_tier_range CHECK (tier >= 1 AND tier <= 5),
    CONSTRAINT uk_badges_tier UNIQUE (tier),
    CONSTRAINT chk_badges_demotion_promotion CHECK (tier = 1 OR demotion_points < promotion_points)
);