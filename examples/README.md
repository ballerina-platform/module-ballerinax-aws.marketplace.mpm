# Examples

The `ballerinax/aws.marketplace.mpm` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/tree/main/examples):

1. [**Meter usage**](./meter-usage/) – Resolves a buyer's registration token into a customer identifier, and reports the usage accumulated for that customer against a product dimension.

## Prerequisites

1. An AWS account registered as a seller, with a published SaaS product on a consumption-based pricing model.
2. For each example, create a `Config.toml` file with your AWS credentials and product details. Here's an example:

```toml
# AWS credentials
accessKeyId = "<YOUR_ACCESS_KEY_ID>"
secretAccessKey = "<YOUR_SECRET_ACCESS_KEY>"

# AWS Marketplace product details
productCode = "<YOUR_PRODUCT_CODE>"
registrationToken = "<BUYER_REGISTRATION_TOKEN>"
```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
