# Meter usage with AWS Marketplace Metering Service

This example demonstrates how to report SaaS usage for an AWS Marketplace product using the Ballerina AWS Marketplace Metering (MPM) connector. It showcases:

- Instantiating the `mpm:Client` with static AWS credentials
- Resolving a buyer's registration token into a customer identifier
- Submitting a usage record for that customer against a product dimension
- Inspecting the per-record results returned by the batch operation

## Prerequisites

- An AWS account registered as a seller, with a published SaaS product on a consumption-based pricing model
- AWS Access Key ID and Secret Access Key, with the `aws-marketplace:ResolveCustomer` and `aws-marketplace:BatchMeterUsage` permissions
- Ballerina Swan Lake 2201.12.0 or later

## Configuration

Update the `Config.toml` with your AWS credentials, product code, and the registration token presented by the buyer.

```toml
# AWS credentials
accessKeyId = "<YOUR_ACCESS_KEY_ID>"
secretAccessKey = "<YOUR_SECRET_ACCESS_KEY>"

# AWS Marketplace product details
productCode = "<YOUR_PRODUCT_CODE>"
registrationToken = "<BUYER_REGISTRATION_TOKEN>"

# Optional - defaults to the "api_calls" dimension and a quantity of 25
dimension = "<YOUR_PRODUCT_DIMENSION>"
quantity = 25
```

> **Note:** The `dimension` must match one declared on your AWS Marketplace product listing, otherwise the usage record is rejected.
>
> Static credentials keep this example self-contained. Where the application runs with an attached IAM role, or signs in through IAM Identity Center (SSO) or a web identity token, prefer `auth:DEFAULT_CREDENTIALS` so that no access key has to be stored or rotated.

## Run the example

1. Ensure you have updated the `Config.toml` with your AWS credentials and product details.
2. Run the example.

```bash
bal run
```

## References

- [Ballerina AWS Marketplace Metering Module](https://central.ballerina.io/ballerinax/aws.marketplace.mpm)
