// Copyright (c) 2024 WSO2 LLC. (http://www.wso2.com).
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

import ballerina/constraint;
import ballerina/time;
import ballerinax/aws;
import ballerinax/aws.auth;

# Represents the connection configuration for the AWS Marketplace Metering service client.
public type ConnectionConfig record {|
    # Authentication configuration: any standard credential source supported by
    # AWS — static credentials, an AWS profile, STS assume-role,
    # web identity (OIDC), IAM Identity Center (SSO), an external credential
    # process, or the default credential provider chain
    auth:AuthConfig auth;
    # AWS region: an `aws:Region` enum member or a plain region
    # string (e.g., `"us-east-1"`) for regions not yet in the enum
    aws:Region|string region;
    # Optional endpoint options: FIPS/dualstack variants, or a custom
    # endpoint override (e.g. LocalStack, VPC interface endpoints)
    aws:EndpointConfig endpoint?;
|};

# Represents the result retrieved from `ResolveCustomer` operation.
public type ResolveCustomerResponse record {|
    # The AWS account ID associated with the Customer identifier for the individual customer
    string customerAWSAccountId;
    # The unique identifier used to identify an individual customer
    string customerIdentifier;
    # The unique identifier for the Marketplace product
    string productCode;
|};

# Represents the parameters used for `BatchMeterUsage` operation.
public type BatchMeterUsageRequest record {|
    # The unique identifier for the Marketplace product
    @constraint:String {
        pattern: re `^[-a-zA-Z0-9/=:_.@]{1,255}$`
    }
    string productCode;
    # The set of usage records. Each usage record provides information about an instance of product usage. 
    @constraint:Array {
        maxLength: 25
    }
    UsageRecord[] usageRecords = [];
|};

# Represents the details of the quantity of usage for a given product.
#
# The buyer must be identified by exactly one of `customerIdentifier` or `customerAWSAccountId`.
public type UsageRecord record {|
    # The unique identifier used to identify an individual customer, obtained via the `ResolveCustomer` operation.
    # Not supported for new SaaS product integrations - use `customerAWSAccountId` instead
    @constraint:String {
        pattern: re `[\s\S]{1,255}$`
    }
    string customerIdentifier?;
    # The AWS account ID of the buyer
    @constraint:String {
        pattern: re `^[0-9]{1,255}$`
    }
    string customerAWSAccountId?;
    # The dimension for which the usage is being reported
    @constraint:String {
        pattern: re `[\s\S]{1,255}$`
    }
    string dimension;
    # The timestamp when the usage occurred (in UTC)
    time:Utc timestamp;
    # The quantity of usage consumed
    @constraint:Int {
        minValue: 0,
        maxValue: 2147483647
    }
    int quantity?;
    # The list of usage allocations
    @constraint:Array {
        minLength: 1,
        maxLength: 2500
    }
    UsageAllocation[] usageAllocations?;
|};

# Represents a usage allocation for AWS Marketplace metering.
public type UsageAllocation record {|
    # The total quantity allocated to this bucket of usage
    @constraint:Int {
        minValue: 0,
        maxValue: 2147483647
    }
    int allocatedUsageQuantity;
    # The set of tags that define the bucket of usage
    @constraint:Array {
        minLength: 1,
        maxLength: 5
    }
    Tag[] tags?;
|};

# Represents the metadata assigned to a usage allocation.
public type Tag record {|
    # The label that acts as the category for the specific tag values
    @constraint:String {
        pattern: re `^[a-zA-Z0-9+ -=._:/@]{1,100}$`
    }
    string 'key;
    # The descriptor within a tag category (key)
    @constraint:String {
        pattern: re `^[a-zA-Z0-9+ -=._:/@]{1,256}$`
    }
    string value;
|};

# Represents the result retrieved from `BatchMeterUsage` operation.
public type BatchMeterUsageResponse record {|
    # The list of all the `UsageRecord` instances successfully processed
    UsageRecordResult[] results;
    # The list of all the `UsageRecord` instances which were not processed
    UsageRecord[] unprocessedRecords;
|};

# Represents the details regarding the status of a given `UsageRecord` processed by `BatchMeterUsage` operation. 
public type UsageRecordResult record {|
    # The unique identifier for this metering event
    string meteringRecordId?;
    # The status of the individual `UsageRecord` processed by the `BatchMeterUsage` operation
    UsageRecordStatus status?;
    # The `UsageRecord` which was part of the `BatchMeterUsage` request
    UsageRecord usageRecord?;
|};

# Represents the possible status of a `UsageRecord`
public enum UsageRecordStatus {
    # The `UsageRecord` was accepted by the `BatchMeterUsage` operation
    SUCCESS = "Success",
    # The provided customer identifier in the `BatchMeterUsage` request, is not able to use your product
    CUSTOMER_NOT_SUBSCRIBED = "CustomerNotSubscribed",
    # The provided `UsageRecord` matches a previously metered `UsageRecord` in terms of customer, dimension, and time
    DUPLICATE_RECORD = "DuplicateRecord"
}

