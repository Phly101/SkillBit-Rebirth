package phly101.example.skillbit_backend.auth.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.jpa.repository.JpaRepository;

import phly101.example.skillbit_backend.auth.domain.OtpCodePurpose;
import phly101.example.skillbit_backend.auth.domain.OtpEntity;


public interface OtpRepo extends JpaRepository<OtpEntity,UUID>{
    Optional<OtpEntity>  findByUserIdAndPurposeAndUsedFalse(UUID userId,OtpCodePurpose purpose);




}
