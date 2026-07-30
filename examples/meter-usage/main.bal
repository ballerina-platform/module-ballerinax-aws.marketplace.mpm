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

import ballerina/io;
import ballerina/time;
import ballerinax/aws;
import ballerinax/aws.marketplace.mpm;

configurable string accessKeyId = ?;
configurable string secretAccessKey = ?;
configurable string productCode = ?;
configurable string registrationToken = ?;

// The dimension must match one declared on the AWS Marketplace product listing.
configurable string dimension = "api_calls";
configurable int quantity = 25;

public function main() returns error? {
    mpm:Client mpm = check new ({
        region: aws:US_EAST_1,
        auth: {
            accessKeyId,
            secretAccessKey
        }
    });

    // Resolve the registration token the buyer presented into a customer identifier.
    mpm:ResolveCustomerResponse customer = check mpm->resolveCustomer(registrationToken);
    io:println(string `Resolved customer ${customer.customerIdentifier} ` +
        string `(AWS account ${customer.customerAWSAccountId}) for product ${customer.productCode}`);

    // Report the usage accumulated for that customer against a product dimension.
    mpm:BatchMeterUsageResponse response = check mpm->batchMeterUsage(
        productCode = productCode,
        usageRecords = [
            {
                customerIdentifier: customer.customerIdentifier,
                dimension: dimension,
                timestamp: time:utcNow(),
                quantity: quantity
            }
        ]
    );

    io:println(string `Metered ${response.results.length()} record(s), ` +
        string `${response.unprocessedRecords.length()} unprocessed:`);
    foreach mpm:UsageRecordResult usageResult in response.results {
        io:println(string `- customer: ${usageResult.usageRecord?.customerIdentifier ?: "N/A"}, ` +
            string `status: ${usageResult.status ?: "N/A"}, ` +
            string `metering record: ${usageResult.meteringRecordId ?: "N/A"}`);
    }

    check mpm->close();
}
