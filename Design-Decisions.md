## AWS API Gateway
### Built-in scalability and traffic management
API Gateway automatically handles traffic spikes and provides throttling, caching, and request/response transformation without additional infrastructure management, critical for a platform serving global users through Route 53 geo-routing

### Seamless Lambda integration with cost optimization 
Native integration with Lambda functions eliminates the need for load balancers or container orchestration, enabling true serverless architecture where you only pay for actual API calls and execution time

### Enterprise-grade security and compliance
Provides built-in authentication, authorization, API key management, and WAF integration, reducing the security implementation overhead while meeting enterprise compliance requirements


## DynamoDB
### Simplified data model matching use case
The credit tracking system primarily needs simple operations: increment/decrement counters, check limits, and store user quotas. DynamoDB's document-based structure perfectly fits this pattern without the complexity of relational schemas, joins, or ACID transactions across multiple tables that Aurora provides but aren't needed here

### Cost-effective for usage patterns
Aurora requires provisioned compute instances running 24/7 even during low usage periods, while DynamoDB's on-demand pricing aligns with the bursty nature of report generation. For a billing system that may have variable load throughout the day/month, DynamoDB's pay-per-request model provides better cost optimization

### Global replication matching your multi-region strategy
DynamoDB Global Tables provide automatic cross-region replication between Sydney and London regions, ensuring data consistency and low-latency access for your geographically distributed architecture

### Serverless scalability with predictable performance 
Auto-scales read/write capacity based on demand without manual intervention, perfectly complementing your serverless Lambda functions while providing consistent single-digit millisecond latency for your real-time processing workflows


## AWS Lambda:
### Event-driven architecture matching business logic
This event-driven model ensures resources are only consumed when actual business events occur

### Automatic scaling for concurrent report requests
Lambda automatically scales to handle thousands of concurrent report generation requests without pre-provisioning capacity. 

### Cost Optimization Through Pay-Per-Execution

### Automatic High Availability and Fault Tolerance
Lambda automatically distributes functions across multiple Availability Zones and handles failover seamlessly.

### Native Integration with AWS Ecosystem
Seamlessly connects with API Gateway, DynamoDB, SQS, CloudWatch, and other AWS services without additional networking configuration or authentication complexity.


## Amazon SQS
### Decoupling critical vs. non-critical operations 
SQS separates time-sensitive credit validation (handled synchronously) from less critical notification delivery (handled asynchronously). This ensures that customers can continue running reports even if the notification system experiences temporary issues, maintaining core business functionality

### Reliable message delivery for business-critical notifications 
SQS provides guaranteed message delivery with dead letter queues for failed notifications. This ensures customer success teams never miss important alerts about customers approaching their limits, which directly impacts revenue opportunities through plan upgrades

### Handling notification bursts and rate limiting 
SQS smooths out notification spikes (e.g., end-of-month when many customers hit limits) and allows controlled processing rates to avoid overwhelming downstream systems like email services or Slack integrations, preventing notification system failures during peak periods