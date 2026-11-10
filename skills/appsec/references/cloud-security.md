# Cloud Security

## 1. Objective
Prevent cloud privilege escalation, public data exposure, insecure network boundaries, and hardcoded cloud credentials across AWS, Azure, GCP, and Terraform/IaC.

## 2. Threat Model
- **Attackers:** External scanners enumerating public S3/GCS/Blob buckets, SSRF attackers querying instance metadata (IMDSv1), and lateral movers abusing wildcard IAM policies.
- **Attack surface:** IAM roles/policies, object storage ACLs, security groups/firewalls, Terraform state/modules, and CI deployment roles.

## 3. Common Vulnerabilities
- Wildcard IAM permissions (`"Action": "*"`, `"Resource": "*"`) or `iam:PassRole` escalation paths.
- Publicly readable/writable storage buckets or snapshots lacking encryption at rest.
- Security groups exposing SSH (`22`), RDP (`3389`), or database ports (`5432`, `3306`, `6379`) to `0.0.0.0/0`.
- IMDSv1 enabled on EC2 instances (trivially exploited via SSRF).
- Storing Terraform `.tfstate` unencrypted without access control (contains plaintext secrets!).

## 4. Vulnerable Example
```hcl
# Terraform — VULNERABLE: Wildcard IAM + public S3 bucket + open SSH
resource "aws_iam_policy" "app" {
  name   = "app-wildcard"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "*", Resource = "*" }]
  })
}

resource "aws_security_group_rule" "ssh_world" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.web.id
}
```

## 5. Secure Example
```hcl
# Terraform — SECURE: Scoped IAM, private encrypted S3, IMDSv2 required
resource "aws_s3_bucket_public_access_block" "assets" {
  bucket                  = aws_s3_bucket.assets.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = "t3.micro"
  metadata_options {
    http_tokens   = "required" # Enforce IMDSv2
    http_endpoint = "enabled"
  }
}
```

## 6. Framework Notes
- **IAM:** Scope both `Action` and `Resource` to exact ARNs/prefixes; enforce MFA/OIDC for human and CI access.
- **Metadata:** Require IMDSv2 (`http_tokens = "required"`) on AWS, `Metadata-Flavor: Google` on GCP, and private endpoints for PaaS databases.
- **IaC:** Store state in encrypted, locked remote backends; avoid passing raw secrets in Terraform variables checked into git.

## 7. Detection Strategy
- Run `trivy config` or `checkov` when available; review `*.tf`, CloudFormation, and IAM JSON files for `*` actions, `0.0.0.0/0` ingress, and missing encryption/public-access blocks.

## 8. Remediation
- Replace wildcard policies with least-privilege service-specific actions, close public admin/DB ports behind VPN/bastion/SSM, and enable bucket public-access blocks + KMS encryption.

## 9. Testing Requirements
- Validate IaC changes with `terraform plan` + static IaC checks in CI before applying to any environment.

## 10. Standards References
- OWASP Top 10 (2021) — A05:2021 Security Misconfiguration
- CIS Cloud Foundations Benchmarks (AWS / Azure / GCP)
- NIST SSDF 1.1 (PO.5, PW.7)
- CWE-250, CWE-284, CWE-732

