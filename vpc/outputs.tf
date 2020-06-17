output "this_vpc_id" {
  description = "The ID of the VPC"
  value       = "${aws_vpc.selected.id}"
}

output "this_subnet_primary_id" {
  description = "The ID of the primary subnet"
  value       = "${aws_subnet.primary-subnet.id}"
}
