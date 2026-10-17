# 10. admin ERD

![admin ERD](admin.png)

## Interactive Mermaid Source
```mermaid
erDiagram
    users ||--o| admins: "can be promoted to"

    users {
        UUID id PK
    }

    admins {
        UUID user_id PK, FK
        TIMESTAMPTZ created_at
    }
```