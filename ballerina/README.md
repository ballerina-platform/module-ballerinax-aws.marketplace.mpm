## Overview

[AWS Marketplace Metering Service](https://docs.aws.amazon.com/marketplacemetering/latest/APIReference/Welcome.html) is a usage and billing service that allows AWS Marketplace sellers to report the usage of their products for billing purposes. This service supports both software-as-a-service (SaaS) products and metering products sold through AWS Marketplace.

The AWS Marketplace Metering Service connector provides APIs to interact with the service, enabling developers to submit usage records, batch meter usage data, and manage metering-related tasks programmatically.

### Key Features

- Report usage of products for billing purposes
- Resolve a buyer's registration token into a customer identifier (`resolveCustomer`)
- Submit usage records for up to 25 buyers at a time from a SaaS backend (`batchMeterUsage`)
- Split reported usage into tagged buckets via usage allocations

## Setup guide

### Prerequisite: an AWS Marketplace seller account

The AWS Marketplace Metering Service is a seller-side API: it reports the usage of *your* products so AWS can bill your customers. Before the connector can submit any metering records, you need:

1. An AWS account registered as a seller in the [AWS Marketplace Management Portal](https://aws.amazon.com/marketplace/management/).
2. A published SaaS product on a consumption-based pricing model — SaaS Subscriptions or SaaS Contract with Consumption.
3. The dimensions you report usage against must match the dimensions declared on that product listing.

### Obtain IAM User Credentials

Every request is signed with AWS Signature Version 4, so the connector needs credentials for an identity that is permitted to call the metering APIs. To create an IAM user and generate an access key, follow the [Obtaining IAM user credentials](https://central.ballerina.io/ballerinax/aws/latest#obtaining-iam-user-credentials) guide.

When setting the permissions for that identity, grant only the metering actions this connector calls:

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "aws-marketplace:ResolveCustomer",
                "aws-marketplace:BatchMeterUsage"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```

> **Note:** Temporary, automatically refreshed credentials are recommended over long-lived IAM user access keys. If the metering backend runs with an attached IAM role, or signs in through IAM Identity Center (SSO) or a web identity token, the connector can resolve those credentials at run time with `auth:DEFAULT_CREDENTIALS`, `auth:AssumeRoleConfig`, `auth:WebIdentityConfig`, or `auth:SsoAuthConfig`, so no access key has to be stored or rotated.

## Quickstart

To use the `aws.marketplace.mpm` connector in your Ballerina project, modify the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/aws` and `ballerinax/aws.marketplace.mpm` modules into your Ballerina project.

```ballerina
import ballerinax/aws;
import ballerinax/aws.marketplace.mpm;
```

### Step 2: Instantiate a new connector

Create a new `mpm:Client` by providing the region and authentication configurations.

```ballerina
import ballerinax/aws;
import ballerinax/aws.auth;

mpm:Client mpm = check new ({
    region: aws:US_EAST_1,
    auth: auth:DEFAULT_CREDENTIALS
});
```

The chain tries each of the following in order and takes the first source that yields credentials:

1. Environment variables (`AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY`, and `AWS_WEB_IDENTITY_TOKEN_FILE` if set)
2. The shared config/credentials file's active profile (`AWS_PROFILE`, or `default` if unset) — which may itself resolve via SSO, an external process, or a chained `AssumeRole` call, depending on that profile's configuration
3. Container credentials (ECS/EKS)
4. EC2 instance profile (IMDS)

#### Other authentication methods

##### Profile-based authentication

You can use AWS profile-based authentication as an alternative to static credentials.

```ballerina
mpm:Client mpm = check new ({
   region: aws:US_EAST_1,
   auth: {
      profileName: "myAwsProfile",
      credentialsFilePath: "/path/to/custom/credentials"
   }
});
```

> **Note:** Ensure your AWS credentials file follows the standard format.
>
> ```ini
> [default]
> aws_access_key_id = YOUR_ACCESS_KEY_ID
> aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
>
> [myAwsProfile]
> aws_access_key_id = ANOTHER_ACCESS_KEY_ID
> aws_secret_access_key = ANOTHER_SECRET_ACCESS_KEY
> ```

##### Static credentials

Long-lived access keys can be supplied directly. Use them only where no temporary-credential source is available, and load them from configuration rather than hard-coding them.

```ballerina
configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;

mpm:Client mpm = check new ({
    region: aws:US_EAST_1,
    auth: {
        accessKeyId,
        secretAccessKey
    }
});
```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

```ballerina
mpm:ResolveCustomerResponse response = check mpm->resolveCustomer("<registration-token>");
```

### Step 4: Run the Ballerina application

Use the following command to compile and run the Ballerina program.

```bash
bal run
```

## Examples

The `ballerinax/aws.marketplace.mpm` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/tree/main/examples):

1. [**Meter usage**](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/tree/main/examples/meter-usage) – Resolves a buyer's registration token into a customer identifier, and reports the usage accumulated for that customer against a product dimension.
