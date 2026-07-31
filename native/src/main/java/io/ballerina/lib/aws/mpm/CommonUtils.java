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

import io.ballerina.lib.aws.ErrorUtils;
import io.ballerina.runtime.api.creators.ErrorCreator;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.flags.SymbolFlags;
import io.ballerina.runtime.api.types.ArrayType;
import io.ballerina.runtime.api.types.RecordType;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BError;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import io.ballerina.stdlib.time.nativeimpl.Utc;
import software.amazon.awssdk.services.marketplacemetering.model.BatchMeterUsageRequest;
import software.amazon.awssdk.services.marketplacemetering.model.BatchMeterUsageResponse;
import software.amazon.awssdk.services.marketplacemetering.model.ResolveCustomerResponse;
import software.amazon.awssdk.services.marketplacemetering.model.Tag;
import software.amazon.awssdk.services.marketplacemetering.model.UsageAllocation;
import software.amazon.awssdk.services.marketplacemetering.model.UsageRecord;
import software.amazon.awssdk.services.marketplacemetering.model.UsageRecordResult;
import software.amazon.awssdk.services.marketplacemetering.model.UsageRecordResultStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/**
 * {@code CommonUtils} contains the common utility functions for the Ballerina AWS MPM connector.
 */
public final class CommonUtils {
    private static final RecordType USAGE_RECORD_RESULT_REC_TYPE = TypeCreator.createRecordType(
            Constants.MPM_USAGE_RECORD_RESULT, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true, 0);
    private static final ArrayType USAGE_RECORD_RESULT_ARR_TYPE = TypeCreator.createArrayType(
            USAGE_RECORD_RESULT_REC_TYPE);
    private static final RecordType USAGE_RECORD_REC_TYPE = TypeCreator.createRecordType(
            Constants.MPM_USAGE_RECORD, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true, 0);
    private static final ArrayType USAGE_RECORD_ARR_TYPE = TypeCreator.createArrayType(USAGE_RECORD_REC_TYPE);
    private static final RecordType USAGE_ALLOC_REC_TYPE = TypeCreator.createRecordType(
            Constants.MPM_USAGE_ALLOC, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true, 0);
    private static final ArrayType USAGE_ALLOC_ARR_TYPE = TypeCreator.createArrayType(USAGE_ALLOC_REC_TYPE);
    private static final RecordType TAG_REC_TYPE = TypeCreator.createRecordType(
            Constants.MPM_TAG, ModuleUtils.getModule(), SymbolFlags.PUBLIC, true, 0);
    private static final ArrayType TAG_ARR_TYPE = TypeCreator.createArrayType(TAG_REC_TYPE);

    private CommonUtils() {
    }

    public static BMap<BString, Object> getBResolveCustomerResponse(ResolveCustomerResponse nativeResponse) {
        BMap<BString, Object> resolveCustomerResponse = ValueCreator.createRecordValue(
                ModuleUtils.getModule(), Constants.MPM_RESOLVE_CUSTOMER);
        resolveCustomerResponse.put(Constants.MPM_RESOLVE_CUSTOMER_AWS_ACNT_ID,
                StringUtils.fromString(nativeResponse.customerAWSAccountId()));
        resolveCustomerResponse.put(Constants.MPM_RESOLVE_CUSTOMER_IDNFR,
                StringUtils.fromString(nativeResponse.customerIdentifier()));
        resolveCustomerResponse.put(Constants.MPM_RESOLVE_CUSTOMER_PRODUCT_CODE,
                StringUtils.fromString(nativeResponse.productCode()));
        return resolveCustomerResponse;
    }

    @SuppressWarnings("unchecked")
    public static BatchMeterUsageRequest getNativeBatchMeterUsageRequest(BMap<BString, Object> request) {
        String productCode = request.getStringValue(Constants.MPM_BATCH_METER_USAGE_PRODUCT_CODE).getValue();
        BatchMeterUsageRequest.Builder requestBuilder = BatchMeterUsageRequest.builder().productCode(productCode);
        BArray usageRecords = request.getArrayValue(Constants.MPM_BATCH_METER_USAGE_RECORDS);
        List<UsageRecord> nativeUsageRecords = new ArrayList<>();
        for (int i = 0; i < usageRecords.size(); i++) {
            BMap<BString, Object> bUsageRecord = (BMap) usageRecords.get(i);
            UsageRecord usageRecord = toNativeUsageRecord(bUsageRecord);
            nativeUsageRecords.add(usageRecord);
        }
        return requestBuilder.usageRecords(nativeUsageRecords).build();
    }

    private static UsageRecord toNativeUsageRecord(BMap<BString, Object> bUsageRecord) {
        String dimension = bUsageRecord.getStringValue(Constants.MPM_USAGE_RECORD_DIMENSION).getValue();
        BArray timestamp = bUsageRecord.getArrayValue(Constants.MPM_USAGE_RECORD_TIMESTAMP);
        Utc utcTimestamp = new Utc(timestamp);
        UsageRecord.Builder builder = UsageRecord.builder()
                .dimension(dimension)
                .timestamp(utcTimestamp.generateInstant());
        if (bUsageRecord.containsKey(Constants.MPM_USAGE_RECORD_CUSTOMER_IDFR)) {
            builder = builder.customerIdentifier(
                    bUsageRecord.getStringValue(Constants.MPM_USAGE_RECORD_CUSTOMER_IDFR).getValue());
        }
        if (bUsageRecord.containsKey(Constants.MPM_USAGE_RECORD_CUSTOMER_AWS_ACNT_ID)) {
            builder = builder.customerAWSAccountId(
                    bUsageRecord.getStringValue(Constants.MPM_USAGE_RECORD_CUSTOMER_AWS_ACNT_ID).getValue());
        }
        if (bUsageRecord.containsKey(Constants.MPM_USAGE_RECORD_QUANTITY)) {
            builder = builder.quantity(bUsageRecord.getIntValue(Constants.MPM_USAGE_RECORD_QUANTITY).intValue());
        }
        if (bUsageRecord.containsKey(Constants.MPM_USAGE_RECORD_USAGE_ALLOCATION)) {
            builder = builder.usageAllocations(toNativeUsageAllocations(
                    bUsageRecord.getArrayValue(Constants.MPM_USAGE_RECORD_USAGE_ALLOCATION)));
        }
        return builder.build();
    }

    @SuppressWarnings("unchecked")
    private static List<UsageAllocation> toNativeUsageAllocations(BArray bUsageAllocations) {
        List<UsageAllocation> nativeUsageAllocations = new ArrayList<>();
        for (int i = 0; i < bUsageAllocations.size(); i++) {
            BMap<BString, Object> bUsageAllocation = (BMap) bUsageAllocations.get(i);
            nativeUsageAllocations.add(toNativeUsageAllocation(bUsageAllocation));
        }
        return nativeUsageAllocations;
    }

    @SuppressWarnings("unchecked")
    private static UsageAllocation toNativeUsageAllocation(BMap<BString, Object> bUsageAllocation) {
        int allocatedQuantity = bUsageAllocation.getIntValue(Constants.MPM_USAGE_ALLOC_USAGE_QUANTITY).intValue();
        UsageAllocation.Builder builder = UsageAllocation.builder().allocatedUsageQuantity(allocatedQuantity);
        if (bUsageAllocation.containsKey(Constants.MPM_USAGE_ALLOC_TAGS)) {
            BArray tags = bUsageAllocation.getArrayValue(Constants.MPM_USAGE_ALLOC_TAGS);
            List<Tag> nativeTags = new ArrayList<>();
            for (int i = 0; i < tags.size(); i++) {
                BMap<BString, Object> bTag = (BMap) tags.get(i);
                String key = bTag.getStringValue(Constants.MPM_TAG_KEY).getValue();
                String value = bTag.getStringValue(Constants.MPM_TAG_VALUE).getValue();
                Tag nativeTag = Tag.builder().key(key).value(value).build();
                nativeTags.add(nativeTag);
            }
            builder = builder.tags(nativeTags);
        }
        return builder.build();
    }

    public static BMap<BString, Object> getBBatchMeterUsageResponse(BatchMeterUsageResponse nativeResponse) {
        BMap<BString, Object> batchMeterUsageResponse = ValueCreator.createRecordValue(
                ModuleUtils.getModule(), Constants.MPM_BATCH_METER_USAGE_RESPONSE);
        BArray usageRecordResults = ValueCreator.createArrayValue(USAGE_RECORD_RESULT_ARR_TYPE);
        nativeResponse.results().forEach(result -> {
            BMap<BString, Object> bUsageRecordResult = toBUsageRecordResult(result);
            usageRecordResults.append(bUsageRecordResult);
        });
        batchMeterUsageResponse.put(Constants.MPM_BATCH_METER_USAGE_RESPONSE_RESULTS, usageRecordResults);
        BArray unprocessedRecords = ValueCreator.createArrayValue(USAGE_RECORD_ARR_TYPE);
        nativeResponse.unprocessedRecords().forEach(unprocessedRecord -> {
            BMap<BString, Object> bUsageRecord = toBUsageRecord(unprocessedRecord);
            unprocessedRecords.append(bUsageRecord);
        });
        batchMeterUsageResponse.put(Constants.MPM_BATCH_METER_USAGE_RESPONSE_UNPROC_RECORDS, unprocessedRecords);
        return batchMeterUsageResponse;
    }

    private static BMap<BString, Object> toBUsageRecordResult(UsageRecordResult nativeUsageRecordResult) {
        BMap<BString, Object> bUsageRecordResult = ValueCreator.createRecordValue(USAGE_RECORD_RESULT_REC_TYPE);
        String meteringRecordId = nativeUsageRecordResult.meteringRecordId();
        if (Objects.nonNull(meteringRecordId)) {
            bUsageRecordResult.put(
                    Constants.MPM_USAGE_RECORD_RESULT_METERING_RECORD, StringUtils.fromString(meteringRecordId));
        }
        UsageRecordResultStatus status = nativeUsageRecordResult.status();
        if (Objects.nonNull(status)) {
            bUsageRecordResult.put(Constants.MPM_USAGE_RECORD_RESULT_STATUS, StringUtils.fromString(status.toString()));
        }
        UsageRecord usageRecord = nativeUsageRecordResult.usageRecord();
        if (Objects.nonNull(usageRecord)) {
            BMap<BString, Object> bUsageRecord = toBUsageRecord(usageRecord);
            bUsageRecordResult.put(Constants.MPM_USAGE_RECORD_RESULT_USAGE_RECORD, bUsageRecord);
        }
        return bUsageRecordResult;
    }

    private static BMap<BString, Object> toBUsageRecord(UsageRecord nativeUsageRecord) {
        BMap<BString, Object> bUsageRecord = ValueCreator.createRecordValue(USAGE_RECORD_REC_TYPE);
        String customerIdentifier = nativeUsageRecord.customerIdentifier();
        if (Objects.nonNull(customerIdentifier)) {
            bUsageRecord.put(
                    Constants.MPM_USAGE_RECORD_CUSTOMER_IDFR, StringUtils.fromString(customerIdentifier));
        }
        String customerAWSAccountId = nativeUsageRecord.customerAWSAccountId();
        if (Objects.nonNull(customerAWSAccountId)) {
            bUsageRecord.put(
                    Constants.MPM_USAGE_RECORD_CUSTOMER_AWS_ACNT_ID, StringUtils.fromString(customerAWSAccountId));
        }
        bUsageRecord.put(Constants.MPM_USAGE_RECORD_DIMENSION, StringUtils.fromString(nativeUsageRecord.dimension()));
        bUsageRecord.put(Constants.MPM_USAGE_RECORD_TIMESTAMP, new Utc(nativeUsageRecord.timestamp()).build());
        Integer quantity = nativeUsageRecord.quantity();
        if (Objects.nonNull(quantity)) {
            bUsageRecord.put(Constants.MPM_USAGE_RECORD_QUANTITY, quantity);
        }
        List<UsageAllocation> nativeUsageAllocation = nativeUsageRecord.usageAllocations();
        if (Objects.nonNull(nativeUsageAllocation) && !nativeUsageAllocation.isEmpty()) {
            BArray usageAllocations = ValueCreator.createArrayValue(USAGE_ALLOC_ARR_TYPE);
            nativeUsageAllocation.forEach(usageAllocation -> {
                BMap<BString, Object> bUsageAllocation = toBUsageAllocation(usageAllocation);
                usageAllocations.append(bUsageAllocation);
            });
            bUsageRecord.put(Constants.MPM_USAGE_RECORD_USAGE_ALLOCATION, usageAllocations);
        }
        return bUsageRecord;
    }

    private static BMap<BString, Object> toBUsageAllocation(UsageAllocation nativeUsageAllocation) {
        BMap<BString, Object> bUsageAllocation = ValueCreator.createRecordValue(USAGE_ALLOC_REC_TYPE);
        bUsageAllocation.put(
                Constants.MPM_USAGE_ALLOC_USAGE_QUANTITY, nativeUsageAllocation.allocatedUsageQuantity());
        List<Tag> nativeTags = nativeUsageAllocation.tags();
        if (Objects.nonNull(nativeTags) && !nativeTags.isEmpty()) {
            BArray tags = ValueCreator.createArrayValue(TAG_ARR_TYPE);
            nativeTags.forEach(t -> {
                BMap<BString, Object> bTag = ValueCreator.createRecordValue(TAG_REC_TYPE);
                bTag.put(Constants.MPM_TAG_KEY, StringUtils.fromString(t.key()));
                bTag.put(Constants.MPM_TAG_VALUE, StringUtils.fromString(t.value()));
                tags.append(bTag);
            });
            bUsageAllocation.put(Constants.MPM_USAGE_ALLOC_TAGS, tags);
        }
        return bUsageAllocation;
    }

    public static BError createError(String message, Throwable exception) {
        BError cause = ErrorCreator.createError(exception);
        BMap<BString, Object> errorDetails = ErrorUtils.createErrorDetails(exception);
        return ErrorCreator.createError(
                ModuleUtils.getModule(), Constants.MPM_ERROR, StringUtils.fromString(message), cause, errorDetails);
    }
}
