# Used for internal routing only - it's a private zone in Route53
resource "aws_route53_zone" "internal" {
  name    = "etleap.internal"
  comment = "Internal DNS for Etleap VPC"
  vpc {
    vpc_id = aws_vpc.etleap.id
  }
}

resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.internal.id
  name    = "dbprod.etleap.internal."
  type    = "CNAME"
  ttl     = "60"
  records = [aws_db_instance.db.address]
}

resource "aws_route53_record" "db-replica" {
  zone_id = aws_route53_zone.internal.id
  name    = "dbprod-read-replica.etleap.internal."
  type    = "CNAME"
  ttl     = "60"
  records = [aws_db_instance.db.address]
}

resource "aws_route53_record" "emr" {
  zone_id = aws_route53_zone.internal.id
  name    = "emr.etleap.internal."
  type    = "CNAME"
  ttl     = "5"
  records = [aws_emr_cluster.emr.master_public_dns]
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.internal.id
  name    = "app.etleap.internal."
  type    = "CNAME"
  ttl     = "5"
  records = [aws_instance.app.private_dns]
}
