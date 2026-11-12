package phly101.example.skillbit_backend.common.dto;

public record FieldViolation (
    String field,
    String message,
    String code
) {
    
}
