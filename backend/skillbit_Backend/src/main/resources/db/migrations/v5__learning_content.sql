CREATE TABLE levels
(
    id             UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    slug           VARCHAR(100) NOT NULL,
    title          VARCHAR(100) NOT NULL,
    sequence_order INT          NOT NULL CHECK (sequence_order > 0),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_levels_slug UNIQUE (slug),
    CONSTRAINT uk_levels_sequence_order UNIQUE (sequence_order)
);

CREATE TABLE courses
(
    id             UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    level_id       UUID         NOT NULL REFERENCES levels (id) ON DELETE RESTRICT,
    slug           VARCHAR(100) NOT NULL,
    title          VARCHAR(150) NOT NULL,
    summary        TEXT         NOT NULL,
    image_url      VARCHAR(500) NOT NULL,
    is_mandatory   BOOLEAN      NOT NULL DEFAULT TRUE,
    is_published   BOOLEAN      NOT NULL DEFAULT FALSE,
    points         INT          NOT NULL CHECK (points > 0),
    sequence_order INT          NOT NULL CHECK (sequence_order > 0),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_courses_slug UNIQUE (slug),
    CONSTRAINT uk_courses_level_sequence UNIQUE (level_id, sequence_order)
);

CREATE TABLE sections
(
    id             UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    course_id      UUID         NOT NULL REFERENCES courses (id) ON DELETE CASCADE,
    slug           VARCHAR(100) NOT NULL,
    title          VARCHAR(150) NOT NULL,
    sequence_order INT          NOT NULL CHECK (sequence_order > 0),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_sections_course_slug UNIQUE (course_id, slug),
    CONSTRAINT uk_sections_course_sequence UNIQUE (course_id, sequence_order)
);
CREATE INDEX idx_sections_course_id ON sections (course_id);

CREATE TABLE quizzes
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    section_id UUID         NOT NULL REFERENCES sections (id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_quizzes_section_id UNIQUE (section_id)
);

CREATE TABLE lessons
(
    id             UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    section_id     UUID         NOT NULL REFERENCES sections (id) ON DELETE CASCADE,
    slug           VARCHAR(100) NOT NULL,
    title          VARCHAR(150) NOT NULL,
    description    TEXT         NOT NULL,
    video_url      VARCHAR(500),
    article_url    VARCHAR(500),
    sequence_order INT          NOT NULL CHECK (sequence_order > 0),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_lessons_section_slug UNIQUE (section_id, slug),
    CONSTRAINT uk_lessons_section_sequence UNIQUE (section_id, sequence_order),
    CONSTRAINT chk_lesson_has_content CHECK (video_url IS NOT NULL OR article_url IS NOT NULL)
);


CREATE TABLE topics
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    name       VARCHAR(50)  NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_topics_name UNIQUE (name)
);

CREATE TABLE lesson_topics
(
    lesson_id UUID NOT NULL REFERENCES lessons (id) ON DELETE CASCADE,
    topic_id  UUID NOT NULL REFERENCES topics (id) ON DELETE CASCADE,
    PRIMARY KEY (lesson_id, topic_id)
);


CREATE TABLE roadmaps
(
    id         UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    slug       VARCHAR(100) NOT NULL,
    title      VARCHAR(150) NOT NULL,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_roadmaps_slug UNIQUE (slug)
);

CREATE TABLE course_roadmaps
(
    course_id  UUID NOT NULL REFERENCES courses (id) ON DELETE CASCADE,
    roadmap_id UUID NOT NULL REFERENCES roadmaps (id) ON DELETE CASCADE,
    PRIMARY KEY (course_id, roadmap_id)
);
CREATE INDEX idx_course_roadmaps_roadmap_id ON course_roadmaps (roadmap_id);