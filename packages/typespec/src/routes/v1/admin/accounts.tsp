import "@typespec/http";
import "@typespec/openapi";

using Http;
using TypeSpec.OpenAPI;

namespace Admin.ApiV1 {
  @useAuth(AppTemplate.BearerAuth)
  @tag("admin-accounts")
  @summary("Lists customer accounts for Admin Console operators")
  @operationId("listAdminAccounts")
  @get
  @route("/accounts")
  op listAdminAccounts(@query email?: string, @query cursor?: string, @query limit?: int32):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AccountListResponse;
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

  @useAuth(AppTemplate.BearerAuth)
  @tag("admin-accounts")
  @summary("Creates a customer account through the Admin Console")
  @operationId("createAdminAccount")
  @post
  @route("/accounts")
  op createAdminAccount(@body body: AppTemplate.CreateAccountRequest):
    | {
        @statusCode statusCode: 201;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.CreateAccountResponse;
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
        @statusCode statusCode: 409;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };

  @useAuth(AppTemplate.BearerAuth)
  @tag("admin-accounts")
  @summary("Gets one customer account for the Admin Console")
  @operationId("getAdminAccount")
  @get
  @route("/accounts/{accountId}")
  op getAdminAccount(@path accountId: AppTemplate.UlidId):
    | {
        @statusCode statusCode: 200;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AccountDetailResponse;
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
        @statusCode statusCode: 404;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthOperationErrorResponse;
      }
    | {
        @statusCode statusCode: 503;
        @header("Cache-Control") cacheControl: "no-store";
        @body body: AppTemplate.AuthFailureResponse;
      };
}
