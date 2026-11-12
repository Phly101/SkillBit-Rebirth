package phly101.example.skillbit_backend.common.exceptions;

public class ForbiddenException extends ApiException {
    public ForbiddenException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }
    
}
