output "private_key" {
  value = "${tls_private_key.squid.private_key_pem}"
}

output "nlb_dns" {
  value = "${aws_lb.squid.dns_name}"
}
