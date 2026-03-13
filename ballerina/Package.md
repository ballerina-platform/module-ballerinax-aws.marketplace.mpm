## Overview

[AWS Marketplace Metering Service](https://docs.aws.amazon.com/marketplacemetering/latest/APIReference/Welcome.html) is a usage and billing service that allows AWS Marketplace sellers to report the usage of their products for billing purposes. This service supports both software-as-a-service (SaaS) products and metering products sold through AWS Marketplace.

The AWS Marketplace Metering Service connector provides APIs to interact with the service, enabling developers to submit usage records, batch meter usage data, and manage metering-related tasks programmatically.

### Key Features

- Report usage of products for billing purposes
- Submit usage records and batch meter usage data
- Manage metering-related tasks programmatically

## Setup guide
Before using this connector in your Ballerina application, complete the following:
1. Create an [AWS account](https://portal.aws.amazon.com/billing/signup?nc2=h_ct&src=default&redirect_url=https%3A%2F%2Faws.amazon.com%2Fregistration-confirmation#/start)
2. [Obtain tokens](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html)

## Quickstart

To use the `aws.marketplace.mpm` connector in your Ballerina project, modify the `.bal` file as follows:

### Step 1: Import the module

Import the `ballerinax/aws.marketplace.mpm` module into your Ballerina project.

```ballerina
import ballerinax/aws.marketplace.mpm;
```

### Step 2: Instantiate a new connector

Create a new `mpm:Client` by providing the access key ID, secret access key, and the region.

```ballerina
configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;

mpm:Client mpm = check new(region = mpm:US_EAST_1, auth = {
    accessKeyId,
    secretAccessKey
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