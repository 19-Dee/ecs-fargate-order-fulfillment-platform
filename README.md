# AWS ECS Fargate Order Fulfillment Platform

A nine-service Go order platform deployed to AWS ECS Fargate. I built the AWS infrastructure, security, observability and CI/CD layers, then completed and tested the SQS-driven order workflow.

> Original assignment: [PROJECT_REQUIREMENTS.md](PROJECT_REQUIREMENTS.md)

## Architecture

<img width="2065" height="1293" alt="AWS ECS Fargate architecture" src="https://github.com/user-attachments/assets/87a8b3cc-b0d5-4572-b1ed-e29cb45ffd35" />

- Nine ECS services run in private subnets across two Availability Zones.
- A public ALB exposes only the API Gateway and Dashboard API.
- Service Connect handles internal discovery; SQS and a DLQ decouple order processing.
- RDS PostgreSQL stores application data, while Redis supports caching and rate limiting.
- There is no NAT Gateway. Private tasks access AWS services through VPC endpoints.

## Key Technologies

AWS ECS Fargate, ECR, ALB, VPC endpoints, Service Connect, RDS PostgreSQL, ElastiCache Redis, SQS/DLQ, Secrets Manager, CloudWatch, Terraform, GitHub Actions, OIDC, Docker, Trivy and Go.

## Deployment Pipeline

Each service has its own path-scoped workflow. A Payment Service change runs only its pipeline:

```text
Push to main
→ authenticate to AWS with GitHub OIDC
→ build and scan the image with Trivy
→ tag it with the Git commit SHA and push to ECR
→ register a new task-definition revision
→ update the ECS service and wait for stability
```

Terraform runs separately through formatting, validation and `terraform plan`. Infrastructure changes are reviewed and applied manually.

## Secrets Management

The PostgreSQL connection string is stored in Secrets Manager and injected into ECS tasks at startup. GitHub Actions uses OIDC, so no long-lived AWS keys are stored in GitHub.

Running tasks do not automatically reload rotated secrets; a controlled redeployment starts new tasks with the updated value. The current Terraform provisions the database secret only.

## Scaling Strategy

Each service currently runs one on-demand Fargate task with no auto scaling.

For production, stateless APIs could scale on ALB traffic, CPU and memory, while the Worker could scale on SQS backlog. The Scheduler should remain single-active, and database connection limits must be considered before increasing task counts.

## Database Migrations

Five data-owning services currently run idempotent `CREATE ... IF NOT EXISTS` migrations at startup.

For production, versioned migrations should run as a one-off ECS task before deployment, using backward-compatible schema changes.

## Order Lifecycle

```text
Create order → pending → SQS → reserve inventory → charge payment
→ confirmed → processing → create shipment → shipped → delivered
```

The Worker deletes a message only after successful processing. Failures are retried and move to the DLQ after four receives. Payment failure cancels the order, and demo mode completes the delivery step automatically.

## CI/CD and Security

- Independent, path-scoped deployments for all nine services.
- GitHub OIDC authentication with no stored AWS access keys.
- SHA-tagged images, Trivy gating and ECR scan-on-push.
- Private tasks, encrypted data stores and least-privilege IAM roles.
- ECS deployment circuit breakers with automatic rollback.
- Encrypted S3 Terraform state with native state locking.
- CloudWatch logs, dashboard and alarms for ECS, ALB, SQS/DLQ and RDS.

## Operational Lessons

- A missing Worker image tag caused `CannotPullContainerError`; the evidence was in ECS stopped-task details rather than application logs.
- The Worker initially lacked Service Connect client enrolment, causing `order-service` DNS failures and DLQ messages. Enrolling the caller restored the full order lifecycle.
- GitHub Actions exposed an OIDC trust mismatch followed by an `iam:PassRole` denial. CloudTrail identified the token subject, and the deployment role was limited to the required ECS roles.

## Evidence and Demo

### Healthy ECS services and ALB target

<img width="1287" height="784" alt="Healthy ECS services and ALB target" src="https://github.com/user-attachments/assets/24332c72-f562-490f-bbcb-107bdf4dff50" />

### Successful path-scoped deployment

<img width="2553" height="1138" alt="Successful path-scoped deployment" src="https://github.com/user-attachments/assets/2c8018c0-2643-4133-931e-a6d9c50b80ba" />

### Incident evidence

**Worker image-pull failure**

<img width="1145" height="45" alt="Worker CannotPullContainerError" src="https://github.com/user-attachments/assets/a3811fa4-a5db-4af7-9794-ab4dfc53f1a5" />

**Service Connect DNS failure**

<img width="344" height="330" alt="Service Connect DNS failure" src="https://github.com/user-attachments/assets/6b407375-4a4f-474c-8291-2ad8ff1c0d51" />

<img width="399" height="19" alt="Order service DNS lookup error" src="https://github.com/user-attachments/assets/7b4e9af3-6914-4122-94c1-78bb6b027942" />

**GitHub OIDC trust mismatch**

<img width="883" height="229" alt="GitHub OIDC trust mismatch" src="https://github.com/user-attachments/assets/c44f40e7-99d3-41d4-b6d4-a435e8a4e39e" />

### SQS and DLQ

<img width="1311" height="777" alt="SQS and DLQ evidence" src="https://github.com/user-attachments/assets/5189621b-5f6a-4f3c-9aef-b1e199deb1da" />

<img width="1290" height="194" alt="DLQ message evidence" src="https://github.com/user-attachments/assets/3fd81044-e79d-4fcc-a1f1-20b04a96a12b" />

### Demo video

https://github.com/user-attachments/assets/7173443d-4394-4992-9a08-fc2a95ed0401

## Reproducibility and Teardown

Terraform defines the workload and uses remote state. Reproduction requires the backend, GitHub OIDC configuration, database input and service images in ECR.

The stack incurs AWS costs, so it should be destroyed after the demo. ECR repositories may need to be emptied first; keep the remote-state backend if it is shared or required for audit history.
