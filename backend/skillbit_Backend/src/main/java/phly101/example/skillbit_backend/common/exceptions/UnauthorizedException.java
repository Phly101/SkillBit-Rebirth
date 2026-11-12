package phly101.example.skillbit_backend.common.exceptions;

public class UnauthorizedException extends ApiException {
    public UnauthorizedException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }
    
}
