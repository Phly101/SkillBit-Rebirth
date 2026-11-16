package phly101.example.skillbit_backend.auth.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import phly101.example.skillbit_backend.auth.domain.RefreshTokenEntity;

public interface RefreshTokenRepo extends JpaRepository<RefreshTokenEntity, UUID> {

    Optional<RefreshTokenEntity> findByTokenHash(String tokenHash);

    @Modifying
    @Query("""
            UPDATE RefreshTokenEntity r
            SET r.isRevoked = true
            WHERE r.userId = :userId
            AND r.isRevoked = false
            """)
    int revokeAllActiveTokensByUserId(@Param("userId") UUID userId);

}
