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

import ballerina/http;
import ballerina/time;

const int MOCK_SERVER_PORT = 9532;
final string mockServerUrl = string `http://localhost:${MOCK_SERVER_PORT}`;

const string AWS_JSON_CONTENT_TYPE = "application/x-amz-json-1.1";
const string RESOLVE_CUSTOMER_TARGET = "AWSMPMeteringService.ResolveCustomer";
const string BATCH_METER_USAGE_TARGET = "AWSMPMeteringService.BatchMeterUsage";

const string MOCK_ACCESS_KEY_ID = "mock-access-key-id";
const string MOCK_SECRET_ACCESS_KEY = "mock-secret-access-key";
const string SIGV4_ALGORITHM = "AWS4-HMAC-SHA256";

// Stands in for the subscribed product and customer a live run reads from the environment.
const string MOCK_PRODUCT_CODE = "mock-product-code";
const string MOCK_DIMENSION = "users";
const string MOCK_SECONDARY_DIMENSION = "storage";
const string MOCK_CUSTOMER_IDENTIFIER = "mock-customer-0001";
const string MOCK_CUSTOMER_AWS_ACCOUNT_ID = "123456789012";
const string MOCK_REGISTRATION_TOKEN = "mock-registration-token";
const string MOCK_EXPIRED_REGISTRATION_TOKEN = "mock-expired-registration-token";
const string MOCK_REQUEST_ID = "mock-request-id";

// Customers the mock deliberately fails, so the per-record outcomes `BatchMeterUsage` reports
// alongside a 200 response can be exercised.
const string MOCK_UNSUBSCRIBED_CUSTOMER_IDENTIFIER = "mock-customer-unsubscribed";
const string MOCK_UNPROCESSED_CUSTOMER_IDENTIFIER = "mock-customer-unprocessed";

// The `UsageRecordResult` statuses the service reports per record.
const string STATUS_SUCCESS = "Success";
const string STATUS_CUSTOMER_NOT_SUBSCRIBED = "CustomerNotSubscribed";
const string STATUS_DUPLICATE_RECORD = "DuplicateRecord";

// `BatchMeterUsage` only accepts usage that occurred within the last 6 hours, and rejects
// timestamps from the future beyond a small allowance for clock skew.
const decimal MOCK_METERING_WINDOW = 6 * 60 * 60;
const decimal MOCK_CLOCK_SKEW = 5 * 60;

// The dimensions the mock product is metered on. Anything else is rejected by the service.
final readonly & string[] mockDimensions = [MOCK_DIMENSION, MOCK_SECONDARY_DIMENSION];

final http:Listener mockListener = check new (MOCK_SERVER_PORT);

final http:Service mockService = service object {

    isolated resource function post .(http:Request request) returns http:Response|error {
        http:Response? authFailure = validateSigV4Credential(request);
        if authFailure is http:Response {
            return authFailure;
        }
        string target = check request.getHeader("X-Amz-Target");
        byte[] rawPayload = check request.getBinaryPayload();
        json payload = check (check string:fromBytes(rawPayload)).fromJsonString();
        if target == RESOLVE_CUSTOMER_TARGET {
            return handleResolveCustomer(payload);
        }
        if target == BATCH_METER_USAGE_TARGET {
            return handleBatchMeterUsage(payload);
        }
        return awsErrorResponse(400, "UnknownOperationException", string `unsupported target: ${target}`);
    }
};

isolated function validateSigV4Credential(http:Request request) returns http:Response? {
    string|error authorization = request.getHeader("Authorization");
    if authorization is error {
        return awsErrorResponse(403, "MissingAuthenticationTokenException",
                "Request is missing Authentication Token");
    }
    if !authorization.startsWith(SIGV4_ALGORITHM + " ")
            || !authorization.includes(string `Credential=${MOCK_ACCESS_KEY_ID}/`) {
        return awsErrorResponse(403, "InvalidSignatureException",
                "The request signature we calculated does not match the signature you provided");
    }
    return ();
}

isolated function handleResolveCustomer(json payload) returns http:Response|error {
    string registrationToken = check (check payload.RegistrationToken).ensureType();
    if registrationToken == MOCK_EXPIRED_REGISTRATION_TOKEN {
        return awsErrorResponse(400, "ExpiredTokenException",
                "The submitted registration token has expired. Ask the customer to reload the page");
    }
    if registrationToken != MOCK_REGISTRATION_TOKEN {
        return awsErrorResponse(400, "InvalidTokenException", "Registration token is invalid");
    }
    return awsJsonResponse({
        "CustomerAWSAccountId": MOCK_CUSTOMER_AWS_ACCOUNT_ID,
        "CustomerIdentifier": MOCK_CUSTOMER_IDENTIFIER,
        "ProductCode": MOCK_PRODUCT_CODE
    });
}

isolated function handleBatchMeterUsage(json payload) returns http:Response|error {
    string productCode = check (check payload.ProductCode).ensureType();
    if productCode != MOCK_PRODUCT_CODE {
        return awsErrorResponse(400, "InvalidProductCodeException",
                string `The product code ${productCode} is not registered`);
    }
    json[] usageRecords = check (check payload.UsageRecords).ensureType();
    return meterUsageRecords(usageRecords);
}

isolated function meterUsageRecords(json[] usageRecords) returns http:Response|error {
    json[] results = [];
    json[] unprocessedRecords = [];
    string[] meteredKeys = [];
    foreach int i in 0 ..< usageRecords.length() {
        map<json> usageRecord = check usageRecords[i].ensureType();
        string dimension = check usageRecord["Dimension"].ensureType();
        if mockDimensions.indexOf(dimension) is () {
            return awsErrorResponse(400, "InvalidUsageDimensionException",
                    string `The usage dimension ${dimension} is not registered for product ${MOCK_PRODUCT_CODE}`);
        }
        decimal? timestamp = epochSeconds(usageRecord["Timestamp"]);
        if timestamp is () || !isWithinMeteringWindow(timestamp) {
            return awsErrorResponse(400, "TimestampOutOfBoundsException",
                    "Timestamp is out of bounds: usage must have occurred within the past 6 hours");
        }
        string customer = customerKey(usageRecord);
        if customer == MOCK_UNPROCESSED_CUSTOMER_IDENTIFIER {
            unprocessedRecords.push(usageRecord);
            continue;
        }
        if customer == MOCK_UNSUBSCRIBED_CUSTOMER_IDENTIFIER {
            results.push({"Status": STATUS_CUSTOMER_NOT_SUBSCRIBED, "UsageRecord": usageRecord});
            continue;
        }
        string recordKey = string `${customer}|${dimension}|${timestamp.toString()}`;
        if meteredKeys.indexOf(recordKey) !is () {
            results.push({"Status": STATUS_DUPLICATE_RECORD, "UsageRecord": usageRecord});
            continue;
        }
        meteredKeys.push(recordKey);
        results.push({
            "MeteringRecordId": string `mock-metering-record-${(i + 1).toString().padZero(4)}`,
            "Status": STATUS_SUCCESS,
            "UsageRecord": usageRecord
        });
    }
    return awsJsonResponse({"Results": results, "UnprocessedRecords": unprocessedRecords});
}

isolated function customerKey(map<json> usageRecord) returns string {
    json? customerIdentifier = usageRecord["CustomerIdentifier"];
    if customerIdentifier is string {
        return customerIdentifier;
    }
    json? customerAWSAccountId = usageRecord["CustomerAWSAccountId"];
    if customerAWSAccountId is string {
        return customerAWSAccountId;
    }
    return "";
}

isolated function epochSeconds(json value) returns decimal? {
    if value is int {
        return <decimal>value;
    }
    if value is decimal {
        return value;
    }
    if value is float {
        return <decimal>value;
    }
    return ();
}

isolated function isWithinMeteringWindow(decimal timestamp) returns boolean {
    time:Utc now = time:utcNow();
    decimal nowSeconds = <decimal>now[0] + now[1];
    return timestamp >= nowSeconds - MOCK_METERING_WINDOW && timestamp <= nowSeconds + MOCK_CLOCK_SKEW;
}

isolated function awsJsonResponse(json payload) returns http:Response {
    http:Response response = new;
    response.statusCode = http:STATUS_OK;
    response.setHeader("x-amzn-RequestId", MOCK_REQUEST_ID);
    response.setJsonPayload(payload, AWS_JSON_CONTENT_TYPE);
    return response;
}

isolated function awsErrorResponse(int statusCode, string errorType, string message) returns http:Response {
    http:Response response = new;
    response.statusCode = statusCode;
    response.setHeader("x-amzn-RequestId", MOCK_REQUEST_ID);
    response.setHeader("x-amzn-ErrorType", errorType);
    response.setJsonPayload({"__type": errorType, "message": message}, AWS_JSON_CONTENT_TYPE);
    return response;
}
