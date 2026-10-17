
CREATE TABLE lesson_examples
(
    id             UUID PRIMARY KEY      DEFAULT gen_random_uuid(),
    lesson_id      UUID         NOT NULL REFERENCES lessons (id) ON DELETE CASCADE,
    slug           VARCHAR(100) NOT NULL,
    title          VARCHAR(150) NOT NULL,
    description    TEXT         NOT NULL,
    sequence_order INT          NOT NULL CHECK (sequence_order > 0),
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_lesson_examples_lesson_slug UNIQUE (lesson_id, slug),
    CONSTRAINT uk_lesson_examples_lesson_sequence UNIQUE (lesson_id, sequence_order)
);


CREATE TABLE example_code_variants
(
    example_id  UUID        NOT NULL REFERENCES lesson_examples (id) ON DELETE CASCADE,
    language    VARCHAR(50) NOT NULL
        CONSTRAINT chk_example_code_variants_language CHECK (language IN ('CPP', 'JAVA', 'PYTHON')),
    source_code TEXT        NOT NULL,
    output      TEXT        NOT NULL,
    PRIMARY KEY (example_id, language)
);


CREATE TABLE example_visualizations
(
    id             UUID PRIMARY KEY     DEFAULT gen_random_uuid(),
    example_id     UUID        NOT NULL REFERENCES lesson_examples (id) ON DELETE CASCADE,
    renderer       VARCHAR(50) NOT NULL
        CONSTRAINT chk_example_visualizations_renderer CHECK (
            renderer IN ('ARRAY', 'LINKED_LIST', 'TREE', 'GRAPH', 'STACK_QUEUE', 'HASH_TABLE', 'THREAD_TIMELINE')),
    schema_version INT         NOT NULL DEFAULT 1
        CONSTRAINT chk_example_visualizations_schema_version CHECK (schema_version > 0),
    steps          JSONB       NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT clock_timestamp(),
    CONSTRAINT uk_example_visualizations_example UNIQUE (example_id),
    CONSTRAINT chk_example_visualizations_steps CHECK (
        CASE WHEN jsonb_typeof(steps) = 'array' THEN jsonb_array_length(steps) > 0 ELSE FALSE END)
);
