package phly101.example.skillbit_backend.auth.constants;

import java.util.List;

public final class AuthConsts {

    private AuthConsts() {
    }

    public static final String ISSUER = "https://skillbit.example";

    public static final String LOGIN_PATH = "/api/v1/auth/login";
    public static final String SIGNUP_PATH = "/api/v1/auth/signup";

    public static final String GOOGLE_LOGIN_PATH = "/api/v1/auth/google";
    public static final String GITHUB_LOGIN_PATH = "/api/v1/auth/github";

    public static final String OTP_SEND_PATH = "/api/v1/auth/otp/send";
    public static final String OTP_RESEND_PATH = "/api/v1/auth/otp/resend";
    public static final String VERIFY_PATH = "/api/v1/auth/verify";

    public static final String FORGOT_PASSWORD_PATH = "/api/v1/auth/forgot-password";

    public static final String RESET_PASSWORD_PATH = "/api/v1/auth/reset-password";

    public static final String REFRESH_PATH = "/api/v1/auth/refresh";

    public static final String LOGOUT_PATH = "/api/v1/auth/logout";

    public static final List<String> PUBLIC_ENDPOINTS = List.of(
            LOGOUT_PATH,
            LOGIN_PATH,
            SIGNUP_PATH,
            GOOGLE_LOGIN_PATH,
            GITHUB_LOGIN_PATH,
            OTP_SEND_PATH,
            OTP_RESEND_PATH,
            VERIFY_PATH,
            FORGOT_PASSWORD_PATH,
            RESET_PASSWORD_PATH,
            REFRESH_PATH);
}