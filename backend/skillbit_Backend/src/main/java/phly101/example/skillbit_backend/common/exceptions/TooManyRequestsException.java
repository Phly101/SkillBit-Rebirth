package phly101.example.skillbit_backend.common.exceptions;

public class TooManyRequestsException extends ApiException {
    public TooManyRequestsException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }

}
