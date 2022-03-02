{
  "Id": "Intermediate",
  "Version": "2012-10-17",
  "Statement":[{
    "Sid": "AllowSSLRequestsOnly",
    "Action": "s3:*",
    "Effect": "Deny",
    "Resource": [
      "arn:aws:s3:::${intermediate_bucket_name}",
      "arn:aws:s3:::${intermediate_bucket_name}/*"
    ],
    "Condition": {
      "Bool": {
        "aws:SecureTransport": "false"
      }
    },
    "Principal": "*"
    }
%{if length(s3_data_lake_account_ids) > 0}
    ,{
    "Sid": "S3DataLakeReadAccess",
    "Effect":"Allow",
    "Principal": {
      "AWS": [${join(", ", formatlist("\"arn:aws:iam::%s:root\"", s3_data_lake_account_ids))}]
    },
    "Action": [
      "s3:GetObject",
      "s3:ListBucket"
    ],
    "Resource": [
      "${intermediate_bucket_arn}",
      "${intermediate_bucket_arn}/*"
    ]
  }
%{endif}
  ]
}