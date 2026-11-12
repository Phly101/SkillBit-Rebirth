package phly101.example.skillbit_backend.common.dto;

import java.time.Instant;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record SkillBitErrorResponse(
        int status,
        String code,
        String message,
        Instant timestamp,
        String path,
        String traceId,
        List<FieldViolation> details
    ) {
}