# Ballerina AWS Marketplace Metering connector

[![Build](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/actions/workflows/ci.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/actions/workflows/ci.yml)
[![Trivy](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/actions/workflows/trivy-scan.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/actions/workflows/trivy-scan.yml)
[![GraalVM Check](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/actions/workflows/build-with-bal-test-graalvm.yml/badge.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/actions/workflows/build-with-bal-test-graalvm.yml)
[![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerinax-aws.marketplace.mpm.svg)](https://github.com/ballerina-platform/module-ballerinax-aws.marketplace.mpm/commits/main)
[![GitHub Issues](https://img.shields.io/github/issues/ballerina-platform/ballerina-library/module/aws.marketplace.mpm.svg?label=Open%20Issues)](https://github.com/ballerina-platform/ballerina-library/labels/module%2Faws.marketplace.mpm)

[AWS Marketplace Metering Service](https://docs.aws.amazon.com/marketplacemetering/latest/APIReference/Welcome.html) is
a usage and billing service that allows AWS Marketplace sellers to report the usage of their products for
billing purposes. This service supports both software-as-a-service (SaaS) products and metering products sold through
AWS Marketplace.

The `ballerinax/aws.marketplace.mpm` package provides APIs to interact with the AWS Marketplace Metering Service,
enabling developers to submit usage records, batch meter usage data, and manage metering-related tasks programmatically.

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

## Build from the source

### Setting up the prerequisites

1. Download and install Java SE Development Kit (JDK) version 21. You can download it from either of the following sources:

    * [Oracle JDK](https://www.oracle.com/java/technologies/downloads/)
    * [OpenJDK](https://adoptium.net/)

   > **Note:** After installation, remember to set the `JAVA_HOME` environment variable to the directory where JDK was installed.

2. Download and install [Ballerina Swan Lake](https://ballerina.io/).

3. Download and install [Docker](https://www.docker.com/get-started).

   > **Note**: Ensure that the Docker daemon is running before executing any tests.

4. Export Github Personal access token with read package permissions as follows,

    ```bash
    export packageUser=<Username>
    export packagePAT=<Personal access token>
    ```

### Build options

Execute the commands below to build from the source.

1. To build the package:

   ```bash
   ./gradlew clean build
   ```

2. To run the tests:

   ```bash
   ./gradlew clean test
   ```

3. To build the without the tests:

   ```bash
   ./gradlew clean build -x test
   ```

4. To run tests against different environments:

   ```bash
   ./gradlew clean test -Pgroups=<Comma separated groups/test cases>
   ```

5. To debug the package with a remote debugger:

   ```bash
   ./gradlew clean build -Pdebug=<port>
   ```

6. To debug with the Ballerina language:

   ```bash
   ./gradlew clean build -PbalJavaDebug=<port>
   ```

7. Publish the generated artifacts to the local Ballerina Central repository:

    ```bash
    ./gradlew clean build -PpublishToLocalCentral=true
    ```

8. Publish the generated artifacts to the Ballerina Central repository:

   ```bash
   ./gradlew clean build -PpublishToCentral=true
   ```

## Contribute to Ballerina

As an open-source project, Ballerina welcomes contributions from the community.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of conduct

All the contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful links

* For more information go to the [`aws.marketplace.mpm` package](https://central.ballerina.io/ballerinax/aws.marketplace.mpm/latest).
* For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/learn/by-example/).
* Chat live with us via our [Discord server](https://discord.gg/ballerinalang).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.