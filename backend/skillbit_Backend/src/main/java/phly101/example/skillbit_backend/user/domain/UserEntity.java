package phly101.example.skillbit_backend.user.domain;

import java.time.Instant;
import java.util.Locale;
import java.util.UUID;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;

@Entity
@Getter
@Table(name = "users")
public class UserEntity {

    @Id
    @GeneratedValue
    private UUID id;

    @Column(name = "email", nullable = false, length = 256)
    private String email;

    @Column(name = "password_hash", nullable = true, length = 200)
    private String passwordHash;

    @Column(name = "name", nullable = false, length = 50)
    private String name;

    @Column(name = "avatar_url", length = 500)
    private String avatarUrl;

    @Column(name = "badge_id", nullable = false)
    private UUID badgeId;

    @Column(name = "points", nullable = false)
    private int points = 0;

    @Column(name = "is_supporter", nullable = false)
    private boolean supporter = false;

    @Column(name = "is_email_verified", nullable = false)
    private boolean isEmailVerified = false;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt;

    protected UserEntity() {
    }

    public UserEntity(
            String email,
            String passwordHash,
            String name,
            String avatarUrl,
            UUID badgeId,
            Instant createdAt) {
        this.email = normalizeEmail(email);
        this.passwordHash = passwordHash;
        this.name = name;
        this.avatarUrl = avatarUrl;
        this.badgeId = badgeId;
        this.createdAt = createdAt;
    }

    public void changeSupport(boolean supporter) {
        this.supporter = supporter;
    }

    public void changePasswordHash(String newPasswordHash) {
        this.passwordHash = newPasswordHash;
    }

    public void changeEmail(String newEmail) {
        this.email = normalizeEmail(newEmail);
    }

    public void markEmailVerified() {
        this.isEmailVerified = true;
    }

    public void addPoints(int amount) {
        if (amount < 0) {
            throw new IllegalArgumentException("Amount cannot be negative");
        }

        this.points = Math.addExact(this.points, amount);
    }

    public void removePoints(int amount) {
        if (amount < 0) {
            throw new IllegalArgumentException("Amount cannot be negative");
        }

        if (amount > this.points) {
            throw new IllegalArgumentException("Insufficient points");
        }

        this.points -= amount;
    }

    public void changeName(String name) {
        this.name = name;
    }

    public void changeAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    private static String normalizeEmail(String email) {
        if (email == null) {
            throw new IllegalArgumentException("Email cannot be null");
        }

        return email.trim().toLowerCase(Locale.ROOT);
    }
}