# Change Log
This file contains all the notable changes done to the Ballerina AWS Marketplace Metering package through the releases.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

This release revamps the connector's authentication and region configuration to use the shared
[`ballerinax/aws`](https://github.com/ballerina-platform/module-ballerinax-aws) package, so that all AWS
connectors share a single, consistent credential model.
([Revamp Connector Authentication Flow](https://github.com/wso2-enterprise/integration-engineering/issues/2091))

It contains breaking changes. See the "Migrating from 0.2.x" section below.

### Changed
- **[Breaking]** Authentication configuration is now sourced from `ballerinax/aws.auth` instead of being
  defined locally by this package. The `ConnectionConfig.auth` field type changed from `mpm:AuthConfig` to
  `auth:AuthConfig`. This is a widening — the former static credentials remain supported, with six new
  credential sources added.
- **[Breaking]** The `ConnectionConfig.region` field type changed from `mpm:Region` to `aws:Region|string`.
  The `string` alternative allows regions that are not yet present in the `aws:Region` enum to be supplied
  directly.
- **[Breaking]** The detail type of `mpm:Error` changed from `mpm:ErrorDetails` to `aws:ErrorDetails`, so that
  all AWS connectors report failures through a single, shared error detail record. The two records have
  identical fields, with `aws:ErrorDetails` additionally including the optional `requestId` field, so field
  access on the value returned by `error.detail()` continues to work unchanged — only explicit
  `mpm:ErrorDetails` type references need updating.
- **[Breaking]** `UsageRecord.customerIdentifier` is now optional, because a usage record may instead identify
  the buyer through the newly added `customerAWSAccountId`. Record literals that set it continue to work
  unchanged; code that *reads* it off a `UsageRecord` returned by `batchMeterUsage` now gets `string?` rather
  than `string`.
- The minimum supported Ballerina distribution is now `2201.12.0` (Swan Lake Update 12), up from
  `2201.11.0`.

### Removed
- **[Breaking]** `mpm:AuthConfig` has been removed in favour of the `ballerinax/aws.auth` equivalents. Its
  replacement, `auth:StaticAuthConfig`, has the same `accessKeyId`, `secretAccessKey` and optional
  `sessionToken` fields, so inline record literals continue to work unchanged — only explicit type
  references need updating.
- **[Breaking]** `mpm:ErrorDetails` has been removed in favour of `aws:ErrorDetails`. The replacement record
  is structurally identical to the one it replaces.
- **[Breaking]** The `mpm:Region` enum has been removed in favour of `aws:Region`.

### Added
- Support for six additional AWS credential sources, available through `auth:AuthConfig`:
  - `auth:ProfileAuthConfig` — credentials from a named profile in a local AWS credentials file.
  - `auth:AssumeRoleConfig` — temporary credentials obtained by assuming an IAM role via AWS STS.
  - `auth:WebIdentityConfig` — web identity (OIDC) federation, including IAM Roles for Service Accounts (IRSA).
  - `auth:SsoAuthConfig` — AWS IAM Identity Center (SSO).
  - `auth:ProcessAuthConfig` — credentials sourced from an external credential process.
  - `auth:DEFAULT_CREDENTIALS` — the AWS default credential provider chain (environment variables, system
    properties, profile files, container and instance metadata).
- A new optional `ConnectionConfig.endpoint` field of type `aws:EndpointConfig`, for selecting FIPS or
  dualstack endpoint variants and for overriding the endpoint entirely (for example, LocalStack or VPC
  interface endpoints).
- A new optional `requestId` field on `aws:ErrorDetails`, carrying the AWS request ID of the failed call to
  simplify support escalations.
- New `aws:Region` members not present in the former `mpm:Region` enum.
- A new optional `UsageRecord.customerAWSAccountId` field, for reporting usage against the buyer's AWS
  account ID instead of a resolved customer identifier. The field is now sent on `batchMeterUsage` requests
  and read back from responses; previously a usage record could identify the buyer only by
  `customerIdentifier`.

### Fixed
- The `Tag` `key` and `value` constraint patterns accepted a backslash, which the service does not, and are
  now aligned with the service-supported character set.
- Mapping a usage record returned by `batchMeterUsage` that carries no `customerIdentifier` no longer fails
  with a null dereference.
- The credential source's resources are now released when client initialization fails part-way through,
  instead of being left behind with no client to close them.

### Migrating from 0.2.x

Add an `import ballerinax/aws;` alongside the existing MPM import, and qualify region members with `aws:`
rather than `mpm:`. Authentication record literals do not need to change:

```ballerina
// 0.2.x
import ballerinax/aws.marketplace.mpm;

mpm:ConnectionConfig config = {
    region: mpm:US_EAST_1,
    auth: {accessKeyId, secretAccessKey}
};
```

```ballerina
// 1.0.0
import ballerinax/aws;
import ballerinax/aws.marketplace.mpm;

mpm:ConnectionConfig config = {
    region: aws:US_EAST_1,
    auth: {accessKeyId, secretAccessKey}
};
```

Code that referred to the removed authentication type by name must be updated to the `ballerinax/aws.auth`
equivalent. The fields, including the optional `sessionToken`, are unchanged:

```ballerina
// 0.2.x
mpm:AuthConfig authConfig = {accessKeyId, secretAccessKey, sessionToken};
```

```ballerina
// 1.0.0
import ballerinax/aws.auth;

auth:StaticAuthConfig authConfig = {accessKeyId, secretAccessKey, sessionToken};
```

Code that named `mpm:ErrorDetails` when inspecting an error must use `aws:ErrorDetails` instead. Field
access is unchanged:

```ballerina
// 0.2.x
if result is mpm:Error {
    mpm:ErrorDetails details = result.detail();
    io:println(details.errorCode);
}
```

```ballerina
// 1.0.0
if result is mpm:Error {
    aws:ErrorDetails details = result.detail();
    io:println(details.errorCode);
}
```

Code that reads `customerIdentifier` off a `UsageRecord` returned by `batchMeterUsage` must account for the
field now being optional:

```ballerina
// 0.2.x
mpm:UsageRecord record = check usageRecordResult.usageRecord.ensureType();
string customerId = record.customerIdentifier;
```

```ballerina
// 1.0.0
mpm:UsageRecord record = check usageRecordResult.usageRecord.ensureType();
string? customerId = record.customerIdentifier;
```

## [0.2.1] - 2026-03-26

### Changed
- Updated the package overview, key features and keywords. No functional changes.

## [0.2.0] - 2025-02-25

### Changed
- Marked the `mpm:Client` as `isolated`.
- Restructured the package dependencies.
