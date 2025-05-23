data "aws_iam_policy_document" "default" {
  count = module.this.enabled ? 1 : 0

  statement {
    sid = "AWSCloudTrailAclCheck"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      "${var.arn_format}:s3:::${module.this.id}",
    ]
  }

  statement {
    sid = "AWSCloudTrailWrite"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com", "cloudtrail.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${var.arn_format}:s3:::${module.this.id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"

      values = [
        "bucket-owner-full-control",
      ]
    }
  }

  dynamic "statement" {
    for_each = var.access_analyzer_enabled ? [1] : []

    content {
      sid    = "PolicyGenerationBucketPolicy"
      effect = "Allow"

      principals {
        type        = "AWS"
        identifiers = ["*"]
      }

      actions = [
        "s3:GetObject",
        "s3:ListBucket"
      ]

      resources = [
        "${var.arn_format}:s3:::${module.this.id}",
        "${var.arn_format}:s3:::${module.this.id}/AWSLogs/*",
      ]

      condition {
        test     = "StringEquals"
        variable = "aws:PrincipalOrgID"
        values   = [var.organization_id]
      }

      condition {
        test     = "StringLike"
        variable = "aws:PrincipalArn"
        values   = formatlist("arn:aws:iam::%s:role/service-role/AccessAnalyzerMonitorServiceRole*", var.access_analyzer_account_ids)
      }
    }

  }
}

module "s3_bucket" {
  source  = "cloudposse/s3-log-storage/aws"
  version = "1.4.4"

  enabled = module.this.enabled

  acl                                    = var.acl
  policy                                 = join("", data.aws_iam_policy_document.default.*.json)
  force_destroy                          = var.force_destroy
  versioning_enabled                     = var.versioning_enabled
  lifecycle_rule_enabled                 = var.lifecycle_rule_enabled
  lifecycle_prefix                       = var.lifecycle_prefix
  lifecycle_tags                         = var.lifecycle_tags
  noncurrent_version_expiration_days     = var.noncurrent_version_expiration_days
  noncurrent_version_transition_days     = var.noncurrent_version_transition_days
  standard_transition_days               = var.standard_transition_days
  glacier_transition_days                = var.glacier_transition_days
  enable_glacier_transition              = var.enable_glacier_transition
  expiration_days                        = var.expiration_days
  abort_incomplete_multipart_upload_days = var.abort_incomplete_multipart_upload_days
  sse_algorithm                          = var.sse_algorithm
  kms_master_key_arn                     = var.kms_master_key_arn
  block_public_acls                      = var.block_public_acls
  block_public_policy                    = var.block_public_policy
  ignore_public_acls                     = var.ignore_public_acls
  restrict_public_buckets                = var.restrict_public_buckets
  access_log_bucket_name                 = var.access_log_bucket_name

  s3_object_ownership = "BucketOwnerEnforced"

  context = module.this.context
}
