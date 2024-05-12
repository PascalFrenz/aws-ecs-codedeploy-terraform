function isHealthRoute(req: Request) {
    return req.url.endsWith("/health");
}

function isToggleHealthRoute(req: Request) {
    return req.url.includes("/health/toggle");
}

const port = 8080;
let isHealthy: boolean = process.env.IS_HEALTHY === "true" ?? true;

console.log("serving on port " + port);
Bun.serve({
    port,
    async fetch(req: Request): Promise<Response> {
        if (isHealthRoute(req)) {
            return isHealthy
                ? new Response("OK")
                : new Response("Service Unavailable", { status: 503 });
        }

        if (isToggleHealthRoute(req)) {
            isHealthy = !isHealthy;
            return new Response("Health set to " + isHealthy);
        }
        return new Response("It works!");
    }
});

