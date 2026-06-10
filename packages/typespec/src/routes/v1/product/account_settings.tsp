import "@typespec/http";
import "@typespec/openapi";

using Http;
using TypeSpec.OpenAPI;

namespace AppTemplate.ApiV1App {
  @tag("account-settings")
  @summary("Gets the current account settings")
  @operationId("getAccountSettings")
  @get
  @route("/account/settings")
  op getAccountSettings():
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AccountSettingResponse;
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

  @tag("account-settings")
  @summary("Updates the current account settings")
  @operationId("updateAccountSettings")
  @patch(#{ implicitOptionality: false })
  @route("/account/settings")
  op updateAccountSettings(@body body: AppTemplate.UpdateAccountSettingRequest):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AccountSettingResponse;
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
