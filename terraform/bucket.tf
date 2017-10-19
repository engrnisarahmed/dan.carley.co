data "aws_iam_policy_document" "website" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${var.website_name}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket" "website" {
  bucket = "${var.website_name}"
  acl    = "private"
  policy = "${data.aws_iam_policy_document.website.json}"

  website {
    index_document = "index.html"
  }
}
