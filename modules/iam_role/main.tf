/* iam_role */
resource "aws_iam_role" "default" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

resource "aws_iam_policy" "default" {
  count  = length(var.policies)
  name   = var.policies[count.index]["name"]
  policy = var.policies[count.index]["policy"]
}

resource "aws_iam_role_policy_attachment" "default" {
  count      = length(aws_iam_policy.default)
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default[count.index].arn
}


