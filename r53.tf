## Used for making the app available at app.${subdomain_name}
data "aws_route53_zone" "prod_public" {
    zone_id = var.route53_zone_id
}


resource "aws_route53_record" "etleap_hostname_app" {
 zone_id = data.aws_route53_zone.prod_public.zone_id
 name    = "app"
 type    = "A"
 ttl     = "5"
 records = [aws_instance.app.public_ip]
}
