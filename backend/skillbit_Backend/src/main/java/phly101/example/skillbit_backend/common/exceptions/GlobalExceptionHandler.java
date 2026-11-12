package phly101.example.skillbit_backend.common.exceptions;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import jakarta.servlet.http.HttpServletRequest;
import phly101.example.skillbit_backend.common.dto.FieldViolation;
import phly101.example.skillbit_backend.common.dto.SkillBitErrorResponse;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(NotFoundException.class)
    public ResponseEntity<SkillBitErrorResponse> handleNotFound(
            NotFoundException ex, HttpServletRequest request) {
        return build(HttpStatus.NOT_FOUND, ex, request);
    }

    private ResponseEntity<SkillBitErrorResponse> build(
            HttpStatus status, ApiException ex, HttpServletRequest request) {
        return build(status, ex.getErrorCode(), ex.getMessage(), request, null, ex);
    }

    private ResponseEntity<SkillBitErrorResponse> build(
            HttpStatus status, ErrorCode code, String rawMessage,
            HttpServletRequest request, List<FieldViolation> details, Throwable cause) {

        String traceId = UUID.randomUUID().toString();
        boolean serverError = status.is5xxServerError();
        String message = serverError
                ? "Something went wrong, please try again later."
                : rawMessage;

        if (serverError) {
            log.error("[{}] {} - {}", traceId, code, rawMessage, cause);
        } else {
            log.warn("[{}] {} - {}", traceId, code, rawMessage);
        }

        SkillBitErrorResponse body = new SkillBitErrorResponse(
                status.value(), code.name(), message,
                Instant.now(), request.getRequestURI(), traceId, details);
        return ResponseEntity.status(status).body(body);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<SkillBitErrorResponse> handleValidation(
            MethodArgumentNotValidException ex, HttpServletRequest request) {

        List<FieldViolation> details = ex.getBindingResult().getFieldErrors().stream()
                .map(fieldError -> new FieldViolation(
                        fieldError.getField(),
                        fieldError.getDefaultMessage(),
                        toCode(fieldError.getCode())))
                .toList();

        return build(HttpStatus.BAD_REQUEST, ErrorCode.VALIDATION_FAILED,
                "Invalid request parameters.", request, details, ex);
    }

    private String toCode(String constraintViolationCode) {
        if (constraintViolationCode == null) {
            return "INVALID";
        }
        return switch (constraintViolationCode) {
            case "NotNull", "NotBlank", "NotEmpty" -> "REQUIRED";
            case "Size" -> "INVALID_LENGTH";
            case "Min" -> "TOO_SMALL";
            case "Max" -> "TOO_LARGE";
            case "Email", "Pattern" -> "INVALID_FORMAT";
            default -> "INVALID";
        };
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<SkillBitErrorResponse> handleGeneric(Exception ex, HttpServletRequest request) {
        if (ex instanceof org.springframework.web.ErrorResponse springError) {
            HttpStatus status = HttpStatus.valueOf(springError.getStatusCode().value());
            return build(status, ErrorCode.BAD_REQUEST, "Request could not be processed.", request, null, ex);
        }
        return build(HttpStatus.INTERNAL_SERVER_ERROR, ErrorCode.INTERNAL_ERROR, ex.getMessage(), request, null, ex);
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<SkillBitErrorResponse> handleHttpMessageNotReadable(HttpMessageNotReadableException ex,
            HttpServletRequest request) {
        return build(HttpStatus.BAD_REQUEST, ErrorCode.BAD_REQUEST, "Malformed request body", request, null, ex);
    }

    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<SkillBitErrorResponse> handleNoResourceFound(NoResourceFoundException ex,
            HttpServletRequest request) {
        return build(HttpStatus.NOT_FOUND, ErrorCode.NOT_FOUND, "The requested resource was not found", request, null,
                ex);
    }

    @ExceptionHandler(BadRequestException.class)
    public ResponseEntity<SkillBitErrorResponse> handleBadRequest(BadRequestException ex, HttpServletRequest request) {
        return build(HttpStatus.BAD_REQUEST, ex, request);
    }

    @ExceptionHandler(ConflictException.class)
    public ResponseEntity<SkillBitErrorResponse> handleConflict(ConflictException ex, HttpServletRequest request) {
        return build(HttpStatus.CONFLICT, ex, request);
    }

    @ExceptionHandler(ForbiddenException.class)
    public ResponseEntity<SkillBitErrorResponse> handleForbidden(ForbiddenException ex, HttpServletRequest request) {
        return build(HttpStatus.FORBIDDEN, ex, request);
    }

    @ExceptionHandler(TooManyRequestsException.class)
    public ResponseEntity<SkillBitErrorResponse> handleTooManyRequests(TooManyRequestsException ex,
            HttpServletRequest request) {
        return build(HttpStatus.TOO_MANY_REQUESTS, ex, request);
    }

    @ExceptionHandler(UnauthorizedException.class)
    public ResponseEntity<SkillBitErrorResponse> handleUnauthorized(UnauthorizedException ex,
            HttpServletRequest request) {
        return build(HttpStatus.UNAUTHORIZED, ex, request);
    }

    @ExceptionHandler(InternalException.class)
    public ResponseEntity<SkillBitErrorResponse> handleInternalError(InternalException ex, HttpServletRequest request) {
        return build(HttpStatus.INTERNAL_SERVER_ERROR, ex, request);
    }

    @ExceptionHandler(ServiceUnavailableException.class)
    public ResponseEntity<SkillBitErrorResponse> handleServiceUnavailable(ServiceUnavailableException ex,
            HttpServletRequest request) {
        return build(HttpStatus.SERVICE_UNAVAILABLE, ex, request);
    }

}
