#!/bin/bash
set -e

echo "💰 Fetching Azure Cost Management data..."
echo ""

# Get the subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Get current month dates
START_DATE=$(date -u +"%Y-%m-01T00:00:00Z")
END_DATE=$(date -u +"%Y-%m-%dT23:59:59Z")

echo "📅 Period: $START_DATE to $END_DATE"
echo "📋 Subscription: $SUBSCRIPTION_ID"
echo ""

# Fetch costs (requires appropriate permissions)
az consumption usage list \
    --start-date "$START_DATE" \
    --end-date "$END_DATE" \
    --query "[].{Date:usageStart, Cost:pretaxCost, Currency:currency, Service:meterDetails.meterCategory}" \
    --output table 2>/dev/null || {
        echo "⚠️  Unable to fetch detailed consumption data."
        echo "You may need to enable Cost Management permissions."
        echo ""
        echo "Try using Azure Portal to view costs:"
        echo "https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/costanalysis"
    }

echo ""
echo "💡 Tip: For detailed cost analysis, visit the Azure Portal:"
echo "   https://portal.azure.com/#blade/Microsoft_Azure_CostManagement/Menu/overview"
