const port = 8080;
console.log("serving on port " + port);
const applicationName = process.env.APPLICATION_NAME || "example-service";
const environmentName = process.env.ENVIRONMENT_NAME || "development";
const configProfileName = process.env.CONFIG_PROFILE_NAME || "default";
const healthStatusFeatureFlag = process.env.HEALTH_STATUS_FEATURE_FLAG || "isHealthy";

function isHealthRoute(req: Request) {
    return req.url.endsWith("/health");
}

if (environmentName === "development") {
    Bun.serve({
        port,
        async fetch(req: Request): Promise<Response> {
            if (isHealthRoute(req)) {
                // this is a convenient way to test the health status feature flag in development
                const isHealthy = true;
                return isHealthy
                    ? new Response("OK", { status: 200 })
                    : new Response("Service Unavailable", { status: 503 });
            }
            return new Response("It works!");
        }
    });
} else {
    const featureFlagUrl = `http://localhost:2772/applications/${applicationName}/environments/${environmentName}/configurations/${configProfileName}?flag=${healthStatusFeatureFlag}`;
    Bun.serve({
        port,
        async fetch(req: Request): Promise<Response> {

            if (isHealthRoute(req)) {
                const isHealthy = await fetch(featureFlagUrl).then(response => response.json()).then(isHealthy => !!isHealthy.enabled);
                return new Response(
                    isHealthy ? "OK" : "Service Unavailable",
                    { status: isHealthy ? 200 : 503 }
                );
            }
            return new Response("It works!");
        }
    });
}
