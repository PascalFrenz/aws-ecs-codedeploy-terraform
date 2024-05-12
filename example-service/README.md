# Example Service

This is an example service that is used by the infrastructure defined in the [infrastructure](../infrastructure).
It is published as a docker image on the GitLab Registry of this repository.

## Usage

The service offers two endpoints:

* `/health` - returns a 200 if the service is healthy
* `/health/toggle` - toggles the health status of the service

By default, the service is healthy.
This can be controlled by setting the `IS_HEALTHY` environment variable to `"false"`.
