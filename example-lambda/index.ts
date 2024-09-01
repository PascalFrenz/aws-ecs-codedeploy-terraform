import middy from "@middy/core";
import httpErrorHandler from "@middy/http-error-handler";
import {InvokeCommand, LambdaClient} from "@aws-sdk/client-lambda";

const serviceBaseUrl = process.env.SERVICE_BASE_URL;
const lambdaClient = new LambdaClient();

/**
 * This simple lambda function is calling the service to check its status
 * and returns the result to the caller.
 *
 * This means the lambda functions health is directly coupled to the service health.
 */
const lambdaHandler = async (event: any, context: any) => {
    console.log(JSON.stringify(event.body));

    if (!event.body) {
        return await fetch(`${serviceBaseUrl}/health`)
            .then(data => {
                if (data.ok) {
                    return {statusCode: 200, body: "OK"};
                }
                return {statusCode: 503, body: "Service Unavailable"};
            })
            .catch(error => {
                console.log(`Could not reach service at ${serviceBaseUrl}: ` + error);
                return {statusCode: 503, body: "Service Unavailable"};
            });
    }

    const {task, lambdaArn, invocations, waitTimeBetweenInvocations} = JSON.parse(JSON.stringify(event.body));

    // check if the lambda should trigger itself
    if (typeof task === "string" && task === "trigger") {
        if (typeof lambdaArn !== "string") {
            return {statusCode: 400, body: "lambdaArn is required"};
        }
        if (typeof invocations !== "number") {
            return {statusCode: 400, body: "invocations is required"};
        }
        if (typeof waitTimeBetweenInvocations !== "number") {
            return {statusCode: 400, body: "waitTimeBetweenInvocations is required"};
        }

        // check that invocations is a positive number smaller than 100
        if (invocations < 1 || invocations > 100) {
            return {statusCode: 400, body: "invocations must be between 1 and 100"};
        }

        // waitTimeBetweenInvocations is a positive number larger than 100
        if (waitTimeBetweenInvocations < 100) {
            return {statusCode: 400, body: "waitTimeBetweenInvocations must be larger than 100"};
        }

        // trigger the lambda asynchronously by the given rate
        const start = Date.now();
        for (let i = 0; i < invocations; i++) {
            await new Promise(resolve => setTimeout(resolve, waitTimeBetweenInvocations));
            await lambdaClient.send(
                new InvokeCommand({
                    FunctionName: lambdaArn,
                    InvocationType: "Event",
                    Payload: JSON.stringify({})
                })
            );
        }
        const end = Date.now();
        return {statusCode: 200, body: `Triggered ${invocations} invocations of ${lambdaArn} in ${end - start}ms`};
    }
}

export const handler = middy(lambdaHandler)
    .use(httpErrorHandler());


