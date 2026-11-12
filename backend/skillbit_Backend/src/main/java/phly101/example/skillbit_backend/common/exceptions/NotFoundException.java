package phly101.example.skillbit_backend.common.exceptions;

public class NotFoundException extends ApiException {
 public NotFoundException(ErrorCode errorCode, String message) {
        super(errorCode, message);
    }
}
