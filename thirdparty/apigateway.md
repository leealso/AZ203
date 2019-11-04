# Establish API Gateways

## Objectives
* Understand where to use several common policy types: inbound, outbound, and backend.
* Understand which type of policy use to secure API access with OpenID and validate-jwt.

## What is API Management?
API Management is an Azure service that helps you define APIs that can be used internally and externally. These APIs can be used to provide a manageable facade to your services which provides many features such as versioning, security, analytics, and many others.

The purpose of an API Gateway is to take requests from applications over the network and then forward them to a backend service. During that process it can do things like authentication, rate limiting, data transformation, and apply policies both to inbound and outbound information.

## Implement a Simple API Gateway and Policies
1. Create an API Management service using the Azure Portal.

## Policies
Policies are decalarative capabilities of the API service to change the behavior of your API. There are three primary types:
Type | Description | Use cases |
---- | ----------- | --------- |
Inbound | Applied on requests when coming in to the API | Authentication, rate limiting, caching |
Outbound | Applied on outbound information from the API | Filter and transform dat, caching |
Backend | Applied before calling a backend service, and after a response from that service | Transform data, select method. retry |

## References
* [About API Management](https://docs.microsoft.com/en-us/azure/api-management/api-management-key-concepts).
* [Policies in Azure API Management](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-policies).
* [API Management policies](https://docs.microsoft.com/en-us/azure/api-management/api-management-policies).
* [API Management policy samples](https://docs.microsoft.com/en-us/azure/api-management/policy-samples)