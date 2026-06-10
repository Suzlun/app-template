import "@typespec/http";
import "@typespec/openapi";

using Http;
using TypeSpec.OpenAPI;

namespace AppTemplate.ApiV1 {
  @tag("auth")
  @summary("Starts a passkey authentication ceremony")
  @operationId("startPasskeyAuthentication")
  @post
  @route("/auth/passkey/start")
  op startPasskeyAuthentication(@body body: AppTemplate.PasskeyStartRequest): {
    @statusCode statusCode: 200;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.PasskeyStartResponse;
  } | {
    @statusCode statusCode: 400;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthOperationErrorResponse;
  } | {
    @statusCode statusCode: 503;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthFailureResponse;
  };

  @tag("auth")
  @summary("Finishes passkey authentication and returns a credential-mode-specific session")
  @operationId("finishPasskeyAuthentication")
  @post
  @route("/auth/passkey/finish")
  op finishPasskeyAuthentication(@body body: AppTemplate.PasskeyFinishRequest):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.ProductAuthSessionResponse;
      }
    | {
        @statusCode statusCode: 400;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("auth")
  @summary("Accepts a recovery request without revealing account existence")
  @operationId("requestPasskeyRecovery")
  @post
  @route("/auth/recovery")
  op requestPasskeyRecovery(@body body: AppTemplate.RecoveryRequest): {
    @statusCode statusCode: 202;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.RecoveryAcceptedResponse;
  } | {
    @statusCode statusCode: 400;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthOperationErrorResponse;
  } | {
    @statusCode statusCode: 503;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthFailureResponse;
  };

  @tag("auth")
  @summary("Consumes a recovery token and issues a recovery session")
  @operationId("consumeRecoveryToken")
  @post
  @route("/auth/recovery/consume")
  op consumeRecoveryToken(@body body: AppTemplate.RecoveryConsumeRequest): {
    @statusCode statusCode: 200;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.RecoveryConsumeResponse;
  } | {
    @statusCode statusCode: 400;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthOperationErrorResponse;
  } | {
    @statusCode statusCode: 503;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthFailureResponse;
  };

  @tag("auth")
  @summary("Starts a passkey registration ceremony using a recovery session")
  @operationId("startPasskeyRegistration")
  @post
  @route("/auth/passkey/register/start")
  op startPasskeyRegistration(@body body: AppTemplate.PasskeyRegisterStartRequest): {
    @statusCode statusCode: 200;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.PasskeyAddStartResponse;
  } | {
    @statusCode statusCode: 400;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthOperationErrorResponse;
  } | {
    @statusCode statusCode: 503;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthFailureResponse;
  };

  @tag("auth")
  @summary("Finishes a passkey registration ceremony and issues a session")
  @operationId("registerPasskey")
  @post
  @route("/auth/passkey/register")
  op registerPasskey(@body body: AppTemplate.PasskeyRegisterRequest): {
    @statusCode statusCode: 200;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.ProductAuthSessionResponse;
  } | {
    @statusCode statusCode: 400;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthOperationErrorResponse;
  } | {
    @statusCode statusCode: 503;
    @header("Cache-Control") cacheControl: "no-store";
    @body body: AppTemplate.AuthFailureResponse;
  };

  @tag("auth")
  @summary("Refreshes an access token for one auth context")
  @operationId("refreshToken")
  @post
  @route("/auth/contexts/{authContextId}/refresh")
  op refreshToken(
    @path authContextId: AppTemplate.UlidId,
    @body body?: AppTemplate.BearerContextRefreshRequest,
  ):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.RefreshTokenResponse;
      }
    | {
        @statusCode statusCode: 400;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };
}

namespace AppTemplate.ApiV1App {
  @tag("app-auth")
  @summary("Starts a WebAuthn reauthentication ceremony for a high-risk operation")
  @operationId("startReauthentication")
  @post
  @route("/auth/reauth/start")
  op startReauthentication(@body body: AppTemplate.ReauthenticationStartRequest):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.PasskeyStartResponse;
      }
    | {
        @statusCode statusCode: 400;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Finishes a WebAuthn reauthentication ceremony and issues a reauthentication session")
  @operationId("finishReauthentication")
  @post
  @route("/auth/reauth/finish")
  op finishReauthentication(@body body: AppTemplate.ReauthenticationFinishRequest):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.ReauthenticationSessionResponse;
      }
    | {
        @statusCode statusCode: 400;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Revokes the current bearer session")
  @operationId("logout")
  @post
  @route("/auth/logout")
  op logout():
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.LogoutResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Lists registered passkeys for the current account")
  @operationId("listPasskeys")
  @get
  @route("/passkeys")
  op listPasskeys():
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.PasskeyListResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Starts adding a passkey for the current account")
  @operationId("startPasskeyAddition")
  @post
  @route("/passkeys/start")
  op startPasskeyAddition():
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.PasskeyAddStartResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Finishes adding a passkey for the current account")
  @operationId("finishPasskeyAddition")
  @post
  @route("/passkeys/finish")
  op finishPasskeyAddition(@body body: AppTemplate.PasskeyAddFinishRequest):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.PasskeyListResponse;
      }
    | {
        @statusCode statusCode: 400;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Deletes a registered passkey for the current account")
  @operationId("deletePasskey")
  @delete
  @route("/passkeys/{id}")
  op deletePasskey(
    @path id: AppTemplate.UlidId,
    @header("X-Reauth-Session") reauthSession: string,
  ):
    | {
        @statusCode statusCode: 204;
        @header("Cache-Control") cacheControl: "no-store";
      }
    | {
        @statusCode statusCode: 400;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse | AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 409;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Sends a device-link URL to the registered email for adding a passkey on a new device")
  @operationId("sendDeviceLink")
  @post
  @route("/passkeys/send-device-link")
  op sendDeviceLink(@header("X-Reauth-Session") reauthSession: string):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.DeviceLinkResponse;
      }
    | {
        @statusCode statusCode: 400;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse | AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Lists active sessions for the current account")
  @operationId("listSessions")
  @get
  @route("/sessions")
  op listSessions():
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.SessionListResponse;
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Revokes a specific session by ID")
  @operationId("revokeSession")
  @delete
  @route("/sessions/{id}")
  op revokeSession(@path id: AppTemplate.UlidId):
    | {
        @statusCode statusCode: 204;
        @header("Cache-Control") cacheControl: "no-store";
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse | AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @tag("app-auth")
  @summary("Revokes all other sessions except the current one")
  @operationId("revokeOtherSessions")
  @delete
  @route("/sessions/others")
  op revokeOtherSessions():
    | {
        @statusCode statusCode: 204;
        @header("Cache-Control") cacheControl: "no-store";
      }
    | {
        @statusCode statusCode: 401;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 403;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };
}
