// Copyright (c) 2026 WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/os;
import ballerina/test;
import ballerina/time;
import ballerinax/aws;
import ballerinax/aws.auth;

configurable boolean isLiveServer = os:getEnv("IS_LIVE_SERVER") == "true";

configurable string accessKeyId = os:getEnv("BALLERINA_AWS_TEST_ACCESS_KEY_ID");
configurable string secretAccessKey = os:getEnv("BALLERINA_AWS_TEST_SECRET_ACCESS_KEY");
configurable string liveProductCode = os:getEnv("BALLERINA_AWS_MPM_TEST_PRODUCT_CODE");
configurable string liveDimension = os:getEnv("BALLERINA_AWS_MPM_TEST_DIMENSION");
configurable string liveCustomerIdentifier = os:getEnv("BALLERINA_AWS_MPM_TEST_CUSTOMER_IDENTIFIER");
configurable string liveCustomerAWSAccountId = os:getEnv("BALLERINA_AWS_MPM_TEST_CUSTOMER_AWS_ACCOUNT_ID");
configurable string liveRegistrationToken = os:getEnv("BALLERINA_AWS_MPM_TEST_REGISTRATION_TOKEN");

final readonly & aws:Region awsRegion = aws:US_EAST_1;

final readonly & auth:StaticAuthConfig liveAuth = {
    accessKeyId,
    secretAccessKey
};

final readonly & auth:StaticAuthConfig mockAuth = {
    accessKeyId: MOCK_ACCESS_KEY_ID,
    secretAccessKey: MOCK_SECRET_ACCESS_KEY
};

final readonly & auth:StaticAuthConfig unexpectedAuth = {
    accessKeyId: "AKIAIOSFODNN7EXAMPLE",
    secretAccessKey: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
};

final readonly & ConnectionConfig connectionConfig = isLiveServer
    ? {region: awsRegion, auth: liveAuth}
    : {region: awsRegion, auth: mockAuth, endpoint: {customEndpoint: mockServerUrl}};

final string testProductCode = isLiveServer ? liveProductCode : MOCK_PRODUCT_CODE;
final string testDimension = isLiveServer ? liveDimension : MOCK_DIMENSION;
final string testCustomerIdentifier = isLiveServer ? liveCustomerIdentifier : MOCK_CUSTOMER_IDENTIFIER;
final string testCustomerAWSAccountId = isLiveServer ? liveCustomerAWSAccountId : MOCK_CUSTOMER_AWS_ACCOUNT_ID;
final string testRegistrationToken = isLiveServer ? liveRegistrationToken : MOCK_REGISTRATION_TOKEN;

final Client mpmClient = check new (connectionConfig);

@test:BeforeSuite
function startMockService() returns error? {
    if isLiveServer {
        return;
    }
    check mockListener.attach(mockService, "/");
    check mockListener.'start();
}

@test:AfterSuite
function stopMockService() returns error? {
    check mpmClient.close();
    if isLiveServer {
        return;
    }
    check mockListener.gracefulStop();
}

@test:Config {
    groups: ["init"]
}
isolated function testInitWithRegionEnum() returns error? {
    Client mpm = check new (connectionConfig);
    check mpm.close();
}

@test:Config {
    groups: ["init"]
}
isolated function testInitWithRegionString() returns error? {
    ConnectionConfig config = isLiveServer
        ? {region: "us-east-1", auth: liveAuth}
        : {region: "us-east-1", auth: mockAuth, endpoint: {customEndpoint: mockServerUrl}};
    Client mpm = check new (config);
    check mpm.close();
}

@test:Config {
    groups: ["init"]
}
isolated function testInitWithDefaultCredentials() returns error? {
    ConnectionConfig config = isLiveServer
        ? {region: awsRegion, auth: auth:DEFAULT_CREDENTIALS}
        : {region: awsRegion, auth: auth:DEFAULT_CREDENTIALS, endpoint: {customEndpoint: mockServerUrl}};
    Client mpm = check new (config);
    check mpm.close();
}

@test:Config {
    groups: ["init"]
}
isolated function testInitWithAssumeRole() returns error? {
    auth:AssumeRoleConfig assumeRoleAuth = {
        roleArn: "arn:aws:iam::123456789012:role/test",
        roleSessionName: "test-session",
        sourceCredentials: mockAuth
    };
    ConnectionConfig config = isLiveServer
        ? {region: awsRegion, auth: assumeRoleAuth}
        : {region: awsRegion, auth: assumeRoleAuth, endpoint: {customEndpoint: mockServerUrl}};
    Client mpm = check new (config);
    check mpm.close();
}

@test:Config {
    groups: ["resolveCustomer"]
}
function testResolveCustomer() returns error? {
    ResolveCustomerResponse response = check mpmClient->resolveCustomer(testRegistrationToken);
    test:assertEquals(response.productCode, testProductCode);
    test:assertTrue(response.customerIdentifier.length() > 0, "the resolved customer must carry an identifier");
    test:assertTrue(response.customerAWSAccountId.length() > 0, "the resolved customer must carry an account id");
    if !isLiveServer {
        test:assertEquals(response.customerIdentifier, MOCK_CUSTOMER_IDENTIFIER);
        test:assertEquals(response.customerAWSAccountId, MOCK_CUSTOMER_AWS_ACCOUNT_ID);
    }
}

@test:Config {
    groups: ["resolveCustomer"]
}
function testResolveCustomerWithInvalidToken() returns error? {
    ResolveCustomerResponse|Error response = mpmClient->resolveCustomer("invalid-registration-token");
    if response !is Error {
        test:assertFail("expected an unknown registration token to be rejected by the service");
    }
    aws:ErrorDetails details = response.detail();
    test:assertEquals(details.httpStatusCode, 400);
    test:assertTrue(details.requestId is string, "the service error must carry a request id");
    if !isLiveServer {
        test:assertEquals(details.errorCode, "InvalidTokenException");
    }
}

@test:Config {
    groups: ["resolveCustomer"]
}
function testResolveCustomerWithExpiredToken() returns error? {
    if isLiveServer {
        // An expired registration token cannot be arranged against the live service.
        return;
    }
    ResolveCustomerResponse|Error response = mpmClient->resolveCustomer(MOCK_EXPIRED_REGISTRATION_TOKEN);
    if response !is Error {
        test:assertFail("expected an expired registration token to be rejected by the service");
    }
    aws:ErrorDetails details = response.detail();
    test:assertEquals(details.httpStatusCode, 400);
    test:assertEquals(details.errorCode, "ExpiredTokenException");
}

@test:Config {
    groups: ["resolveCustomer"]
}
function testResolveCustomerWithUnexpectedCredentials() returns error? {
    ConnectionConfig config = isLiveServer
        ? {region: awsRegion, auth: unexpectedAuth}
        : {region: awsRegion, auth: unexpectedAuth, endpoint: {customEndpoint: mockServerUrl}};
    Client mpm = check new (config);
    ResolveCustomerResponse|Error response = mpm->resolveCustomer(testRegistrationToken);
    check mpm.close();
    if response !is Error {
        test:assertFail("expected a request signed with unexpected credentials to be rejected");
    }
    test:assertEquals(response.detail().httpStatusCode, 403);
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsage() returns error? {
    BatchMeterUsageResponse response = check mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerIdentifier: testCustomerIdentifier,
                dimension: testDimension,
                timestamp: time:utcNow(),
                quantity: 1
            }
        ]
    );
    test:assertEquals(response.results.length(), 1);
    test:assertEquals(response.unprocessedRecords.length(), 0);
    UsageRecordResult result = response.results[0];
    test:assertEquals(result.status, SUCCESS);
    test:assertTrue(result.meteringRecordId is string, "a metered record must carry a metering record id");
    UsageRecord? meteredRecord = result.usageRecord;
    if meteredRecord is () {
        test:assertFail("the service must echo back the record it metered");
    }
    test:assertEquals(meteredRecord.dimension, testDimension);
    test:assertEquals(meteredRecord.customerIdentifier, testCustomerIdentifier);
    test:assertEquals(meteredRecord.quantity, 1);
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithCustomerAwsAccountId() returns error? {
    BatchMeterUsageResponse response = check mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerAWSAccountId: testCustomerAWSAccountId,
                dimension: testDimension,
                timestamp: time:utcNow(),
                quantity: 2
            }
        ]
    );
    test:assertEquals(response.results.length(), 1);
    UsageRecord? meteredRecord = response.results[0].usageRecord;
    if meteredRecord is () {
        test:assertFail("the service must echo back the record it metered");
    }
    test:assertEquals(meteredRecord.customerAWSAccountId, testCustomerAWSAccountId);
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithUsageAllocations() returns error? {
    BatchMeterUsageResponse response = check mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerIdentifier: testCustomerIdentifier,
                dimension: testDimension,
                timestamp: time:utcNow(),
                quantity: 4,
                usageAllocations: [
                    {allocatedUsageQuantity: 3, tags: [{'key: "tier", value: "gold"}]},
                    {allocatedUsageQuantity: 1, tags: [{'key: "tier", value: "silver"}]}
                ]
            }
        ]
    );
    test:assertEquals(response.results.length(), 1);
    UsageRecord? meteredRecord = response.results[0].usageRecord;
    if meteredRecord is () {
        test:assertFail("the service must echo back the record it metered");
    }
    UsageAllocation[]? allocations = meteredRecord.usageAllocations;
    if allocations is () {
        test:assertFail("the echoed record must carry the usage allocations that were sent");
    }
    test:assertEquals(allocations.length(), 2);
    test:assertEquals(allocations[0].allocatedUsageQuantity, 3);
    test:assertEquals(allocations[0].tags, [{'key: "tier", value: "gold"}]);
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithMultipleRecords() returns error? {
    time:Utc timestamp = time:utcNow();
    BatchMeterUsageResponse response = check mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerIdentifier: testCustomerIdentifier,
                dimension: testDimension,
                timestamp,
                quantity: 1
            },
            {
                customerAWSAccountId: testCustomerAWSAccountId,
                dimension: testDimension,
                timestamp,
                quantity: 1
            }
        ]
    );
    test:assertEquals(response.results.length(), 2);
    if !isLiveServer {
        foreach UsageRecordResult result in response.results {
            test:assertEquals(result.status, SUCCESS);
        }
    }
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithDuplicateRecords() returns error? {
    time:Utc timestamp = time:utcNow();
    UsageRecord usageRecord = {
        customerIdentifier: testCustomerIdentifier,
        dimension: testDimension,
        timestamp,
        quantity: 7
    };
    BatchMeterUsageResponse response = check mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [usageRecord, usageRecord]
    );
    test:assertEquals(response.results.length(), 2);
    if !isLiveServer {
        // The service meters the first record and reports the repeat as a duplicate rather than
        // failing the whole request.
        test:assertEquals(response.results[0].status, SUCCESS);
        test:assertEquals(response.results[1].status, DUPLICATE_RECORD);
        test:assertTrue(response.results[1].meteringRecordId is (),
                "a duplicate record is not assigned a metering record id");
    }
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithUnsubscribedCustomer() returns error? {
    if isLiveServer {
        // A customer that is not subscribed to the live product cannot be arranged.
        return;
    }
    BatchMeterUsageResponse response = check mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerIdentifier: MOCK_UNSUBSCRIBED_CUSTOMER_IDENTIFIER,
                dimension: testDimension,
                timestamp: time:utcNow(),
                quantity: 1
            }
        ]
    );
    test:assertEquals(response.results.length(), 1);
    test:assertEquals(response.results[0].status, CUSTOMER_NOT_SUBSCRIBED);
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithUnprocessedRecord() returns error? {
    if isLiveServer {
        // Which records the live service leaves unprocessed is not something a test can arrange.
        return;
    }
    BatchMeterUsageResponse response = check mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerIdentifier: MOCK_UNPROCESSED_CUSTOMER_IDENTIFIER,
                dimension: testDimension,
                timestamp: time:utcNow(),
                quantity: 1
            }
        ]
    );
    test:assertEquals(response.results.length(), 0);
    test:assertEquals(response.unprocessedRecords.length(), 1);
    test:assertEquals(response.unprocessedRecords[0].customerIdentifier, MOCK_UNPROCESSED_CUSTOMER_IDENTIFIER);
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithUnknownProductCode() returns error? {
    BatchMeterUsageResponse|Error response = mpmClient->batchMeterUsage(
        productCode = "unknown-product-code",
        usageRecords = [
            {
                customerIdentifier: testCustomerIdentifier,
                dimension: testDimension,
                timestamp: time:utcNow(),
                quantity: 1
            }
        ]
    );
    if response !is Error {
        test:assertFail("expected an unregistered product code to be rejected by the service");
    }
    aws:ErrorDetails details = response.detail();
    test:assertEquals(details.httpStatusCode, 400);
    test:assertEquals(details.errorCode, "InvalidProductCodeException");
    test:assertTrue(details.requestId is string, "the service error must carry a request id");
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithUnknownDimension() returns error? {
    BatchMeterUsageResponse|Error response = mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerIdentifier: testCustomerIdentifier,
                dimension: "no-such-dimension",
                timestamp: time:utcNow(),
                quantity: 1
            }
        ]
    );
    if response !is Error {
        test:assertFail("expected an unregistered usage dimension to be rejected by the service");
    }
    aws:ErrorDetails details = response.detail();
    test:assertEquals(details.httpStatusCode, 400);
    test:assertEquals(details.errorCode, "InvalidUsageDimensionException");
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageWithTimestampOutOfBounds() returns error? {
    // 2020-09-13T12:26:40Z: well outside the 6 hour window the service meters against.
    BatchMeterUsageResponse|Error response = mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = [
            {
                customerIdentifier: testCustomerIdentifier,
                dimension: testDimension,
                timestamp: <time:Utc>[1600000000, 0],
                quantity: 1
            }
        ]
    );
    if response !is Error {
        test:assertFail("expected usage older than 6 hours to be rejected by the service");
    }
    aws:ErrorDetails details = response.detail();
    test:assertEquals(details.httpStatusCode, 400);
    test:assertEquals(details.errorCode, "TimestampOutOfBoundsException");
}

@test:Config {
    groups: ["batchMeterUsage"]
}
function testBatchMeterUsageExceedingRecordLimit() returns error? {
    time:Utc timestamp = time:utcNow();
    UsageRecord[] usageRecords = [];
    foreach int i in 1 ... 26 {
        usageRecords.push({
            customerIdentifier: string `${testCustomerIdentifier}-${i}`,
            dimension: testDimension,
            timestamp,
            quantity: 1
        });
    }
    BatchMeterUsageResponse|Error response = mpmClient->batchMeterUsage(
        productCode = testProductCode,
        usageRecords = usageRecords
    );
    if response !is Error {
        test:assertFail("expected more than 25 usage records to be rejected by the connector");
    }
    test:assertTrue(response.message().startsWith("Request validation failed"), response.message());
    test:assertTrue(response.detail().httpStatusCode is (),
            "a request rejected before it was sent must not carry service error details");
}
