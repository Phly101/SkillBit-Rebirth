package phly101.example.skillbit_backend.common.exceptions;

public class BadRequestException extends ApiException {
    public BadRequestException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }
    
}
