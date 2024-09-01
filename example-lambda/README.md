# Example Lambda

This is an example consumer of the example service that is used by the infrastructure defined in the [infrastructure](../infrastructure).
It is published as a lambda function into the given aws account. The source code is pre-transpiled and minified
at `./build/index.mjs`.

## Usage

If you make any changes, do not forget to re-build the file and update your lambda:

1. `bun run build` within this directory
2. go to the `infrastructure` directory
3. run `terraform plan -var-file=config/<your_var_file> -out plan.tfplan`
4. run `terraform apply plan.tfplan`

Now your lambda should be updated.

## Note

The lambda has rights to call itself so make sure you really do not build a recursive lambda loop as those
tend to get very expensive very quickly!
