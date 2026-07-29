/*
 * Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com)
 *
 * WSO2 LLC. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package io.ballerina.lib.aws.mpm;

import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BString;

/**
 * Represents the constants related to Ballerina MPM connector.
 */
public interface Constants {
    // Constants related to MPM `ResolveCustomerResponse`
    String MPM_RESOLVE_CUSTOMER = "ResolveCustomerResponse";
    BString MPM_RESOLVE_CUSTOMER_AWS_ACNT_ID = StringUtils.fromString("customerAWSAccountId");
    BString MPM_RESOLVE_CUSTOMER_IDNFR = StringUtils.fromString("customerIdentifier");
    BString MPM_RESOLVE_CUSTOMER_PRODUCT_CODE = StringUtils.fromString("productCode");

    // Constants related to MPM `BatchMeterUsageRequest`
    BString MPM_BATCH_METER_USAGE_PRODUCT_CODE = StringUtils.fromString("productCode");
    BString MPM_BATCH_METER_USAGE_RECORDS = StringUtils.fromString("usageRecords");

    // Constants related to MPM `UsageRecord`
    String MPM_USAGE_RECORD = "UsageRecord";
    BString MPM_USAGE_RECORD_CUSTOMER_IDFR = StringUtils.fromString("customerIdentifier");
    BString MPM_USAGE_RECORD_CUSTOMER_AWS_ACNT_ID = StringUtils.fromString("customerAWSAccountId");
    BString MPM_USAGE_RECORD_DIMENSION = StringUtils.fromString("dimension");
    BString MPM_USAGE_RECORD_TIMESTAMP = StringUtils.fromString("timestamp");
    BString MPM_USAGE_RECORD_QUANTITY = StringUtils.fromString("quantity");
    BString MPM_USAGE_RECORD_USAGE_ALLOCATION = StringUtils.fromString("usageAllocations");

    // Constants related to MPM `UsageAllocation`
    String MPM_USAGE_ALLOC = "UsageAllocation";
    BString MPM_USAGE_ALLOC_USAGE_QUANTITY = StringUtils.fromString("allocatedUsageQuantity");
    BString MPM_USAGE_ALLOC_TAGS = StringUtils.fromString("tags");

    // Constants related to MPM `Tag`
    String MPM_TAG = "Tag";
    BString MPM_TAG_KEY = StringUtils.fromString("key");
    BString MPM_TAG_VALUE = StringUtils.fromString("value");

    // Constants related to MPM `BatchMeterUsageResponse`
    String MPM_BATCH_METER_USAGE_RESPONSE = "BatchMeterUsageResponse";
    BString MPM_BATCH_METER_USAGE_RESPONSE_RESULTS = StringUtils.fromString("results");
    BString MPM_BATCH_METER_USAGE_RESPONSE_UNPROC_RECORDS = StringUtils.fromString("unprocessedRecords");

    // Constants related to MPM `UsageRecordResult`
    String MPM_USAGE_RECORD_RESULT = "UsageRecordResult";
    BString MPM_USAGE_RECORD_RESULT_METERING_RECORD = StringUtils.fromString("meteringRecordId");
    BString MPM_USAGE_RECORD_RESULT_STATUS = StringUtils.fromString("status");
    BString MPM_USAGE_RECORD_RESULT_USAGE_RECORD = StringUtils.fromString("usageRecord");

    // Constants related to MPM Error
    String MPM_ERROR = "Error";
}
