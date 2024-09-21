resource "aws_ses_domain_identity" "datasektionen" {
  domain = data.cloudflare_zone.datasektionen.name
}

resource "cloudflare_record" "datasektionen_ses_verification" {
  name    = "_amazonses"
  type    = "TXT"
  zone_id = data.cloudflare_zone.datasektionen.id
  value   = aws_ses_domain_identity.datasektionen.verification_token
}

resource "aws_ses_domain_dkim" "datasektionen" {
  domain = data.cloudflare_zone.datasektionen.name
}

resource "cloudflare_record" "datasektionen_ses_dkim" {
  count   = 3
  name    = "${aws_ses_domain_dkim.datasektionen.dkim_tokens[count.index]}._domainkey"
  type    = "CNAME"
  zone_id = data.cloudflare_zone.datasektionen.id
  value   = "${aws_ses_domain_dkim.datasektionen.dkim_tokens[count.index]}.dkim.amazonses.com"
}

resource "aws_ses_domain_mail_from" "datasektionen" {
  domain           = data.cloudflare_zone.datasektionen.name
  mail_from_domain = "sesmail.${data.cloudflare_zone.datasektionen.name}"
}

resource "cloudflare_record" "datasektionen_mail_from_mx" {
  name     = aws_ses_domain_mail_from.datasektionen.mail_from_domain
  type     = "MX"
  zone_id  = data.cloudflare_zone.datasektionen.id
  value    = "feedback-smtp.${local.aws_region}.amazonses.com"
  priority = 10
}

resource "cloudflare_record" "datasektionen_mail_from_spf" {
  name    = aws_ses_domain_mail_from.datasektionen.mail_from_domain
  type    = "TXT"
  zone_id = data.cloudflare_zone.datasektionen.id
  value   = "v=spf1 include:amazonses.com -all"
}

data "aws_iam_policy_document" "send_email" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "send_email" {
  name        = "send_email"
  description = "Allows sending emails via SES"
  policy      = data.aws_iam_policy_document.send_email.json
}

# Mattermost

resource "aws_iam_user" "mattermost_smtp" {
  name = "mattermost_smtp"
}

resource "aws_iam_access_key" "mattermost_smtp" {
  user = aws_iam_user.mattermost_smtp.name
}

resource "aws_iam_user_policy_attachment" "mattermost_smtp" {
  user       = aws_iam_user.mattermost_smtp.name
  policy_arn = aws_iam_policy.send_email.arn
}
