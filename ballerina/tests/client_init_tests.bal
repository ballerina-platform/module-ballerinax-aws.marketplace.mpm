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

// Client initialization coverage for the shared `ballerinax/aws.auth` credential sources, plus
// runtime checks that the AWS SDK jars this package declares line up with the ones contributed
// by `ballerinax/aws`. Requests are aimed at an unused local port, so no AWS account is needed:
// a linkage error would mean the SDK versions are incompatible, whereas a transport failure
// means marshalling and signing completed.

import ballerina/test;
import ballerina/time;
import ballerinax/aws;
import ballerinax/aws.auth;

final readonly & auth:StaticAuthConfig testAuth = {
    accessKeyId: "test-access-key",
    secretAccessKey: "test-secret-key"
};

@test:Config {}
function testInitStaticAuth() returns error? {
    Client mpm = check new ({region: aws:US_EAST_1, auth: testAuth});
    check mpm->close();
}

@test:Config {}
function testInitDefaultCredentials() returns error? {
    Client mpm = check new ({region: aws:US_EAST_1, auth: auth:DEFAULT_CREDENTIALS});
    check mpm->close();
}

@test:Config {}
function testInitRegionStringAndCustomEndpoint() returns error? {
    Client mpm = check new ({
        region: "us-east-1",
        auth: testAuth,
        endpoint: {customEndpoint: "http://localhost:9599"}
    });
    check mpm->close();
}

// Marshals a usage record through the metering model and out over the wire, then fails at the
// transport layer. A linkage error here would mean the AWS SDK jars this package declares do not
// line up with the ones `ballerinax/aws` contributes; a connection failure means marshalling and
// signing completed against a single coherent SDK.
@test:Config {}
function testUsageRecordMarshalling() returns error? {
    Client mpm = check new ({
        region: aws:US_EAST_1,
        auth: testAuth,
        endpoint: {customEndpoint: "http://localhost:9599"}
    });
    BatchMeterUsageResponse|Error response = mpm->batchMeterUsage(
        productCode = "test-product",
        usageRecords = [
            {
                customerAWSAccountId: "123456789012",
                dimension: "units",
                timestamp: <time:Utc>[1753488000, 0],
                quantity: 3,
                usageAllocations: [
                    {
                        allocatedUsageQuantity: 3,
                        tags: [{'key: "tier", value: "gold"}]
                    }
                ]
            }
        ]
    );
    if response !is Error {
        test:assertFail("expected a transport failure against the unused local port");
    }
    test:assertTrue(response.message().length() > 0);
    check mpm->close();
}

// Forces `aws-native`'s ProviderFactory (compiled against the older SDK) to resolve credentials
// and sign a request on top of the newer SDK actually present on the classpath.
@test:Config {}
function testDefaultCredentialsSigning() returns error? {
    Client mpm = check new ({
        region: aws:US_EAST_1,
        auth: auth:DEFAULT_CREDENTIALS,
        endpoint: {customEndpoint: "http://localhost:9599"}
    });
    BatchMeterUsageResponse|Error response = mpm->batchMeterUsage(
        productCode = "test-product",
        usageRecords = [
            {
                customerAWSAccountId: "123456789012",
                dimension: "units",
                timestamp: <time:Utc>[1753488000, 0],
                quantity: 1
            }
        ]
    );
    if response !is Error {
        test:assertFail("expected a transport failure against the unused local port");
    }
    check mpm->close();
}

// An STS assume-role provider is built entirely by `aws-native` against the older SDK; exercising
// it proves the sts jar and the provider factory line up with the newer core.
@test:Config {}
function testAssumeRoleProviderConstruction() returns error? {
    Client|Error mpm = new ({
        region: aws:US_EAST_1,
        auth: <auth:AssumeRoleConfig>{
            roleArn: "arn:aws:iam::123456789012:role/test",
            roleSessionName: "test-session",
            sourceCredentials: testAuth
        },
        endpoint: {customEndpoint: "http://localhost:9599"}
    });
    if mpm is Error {
        test:assertFail("assume-role provider construction failed: " + mpm.message());
    }
    check mpm->close();
}
