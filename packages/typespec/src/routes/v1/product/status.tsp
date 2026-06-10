import "@typespec/http";
import "@typespec/openapi";

using Http;
using TypeSpec.OpenAPI;

namespace AppTemplate.ApiV1;

@tag("status")
@summary("Returns API status")
@operationId("getStatus")
@get
@route("/status")
op getStatus(): {
  @statusCode statusCode: 200;
  @body body: AppTemplate.StatusResponse;
};
