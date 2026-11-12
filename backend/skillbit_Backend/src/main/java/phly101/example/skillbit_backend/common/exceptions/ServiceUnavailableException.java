package phly101.example.skillbit_backend.common.exceptions;

public class ServiceUnavailableException extends ApiException {
    public ServiceUnavailableException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }

}
