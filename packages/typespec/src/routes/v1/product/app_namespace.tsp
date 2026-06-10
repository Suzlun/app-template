import "@typespec/http";

using Http;

@useAuth(BearerAuth)
@route("/api/v1")
namespace AppTemplate.ApiV1App;
