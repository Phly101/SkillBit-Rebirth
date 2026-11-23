package phly101.example.skillbit_backend.auth.domain;

import java.time.Instant;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Getter
@Entity
@Table(name = "otp_codes")
public class OtpEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "user_id", nullable = false)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "purpose", nullable = false)
    private OtpCodePurpose purpose;

    
    @Column(name = "code_hash", nullable = false, length = 255)
    private String codeHash;

    @Setter
    @Column(name = "new_email", length = 256)
    private String newEmail;

    
    @Column(name = "attempts_count", nullable = false)
    private int attemptsCount;

    
    @Column(name = "is_used", nullable = false)
    private boolean used;

    @Column(name = "expires_at", nullable = false)
    private Instant expiresAt;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected OtpEntity() {
    }

    public OtpEntity(
            UUID userId,
            OtpCodePurpose purpose,
            String codeHash,
            Instant expiresAt,
            Instant createdAt
    ) {
        this.userId = userId;
        this.purpose = purpose;
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.createdAt = createdAt;
        this.attemptsCount = 0;
        this.used = false;
    }

    public void renew(
            String codeHash,
            Instant expiresAt,
            Instant createdAt,
            String newEmail
    ) {
        this.codeHash = codeHash;
        this.expiresAt = expiresAt;
        this.createdAt = createdAt;
        this.newEmail = newEmail;
        this.attemptsCount = 0;
        this.used = false;
    }
}