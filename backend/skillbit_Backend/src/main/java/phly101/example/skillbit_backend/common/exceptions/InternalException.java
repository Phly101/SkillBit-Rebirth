package phly101.example.skillbit_backend.common.exceptions;

public class InternalException extends ApiException {
    public InternalException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }
 
}
