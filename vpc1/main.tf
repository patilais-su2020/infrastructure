module "vpc1" {
  source = "../vpc/"
  vpc_id = "${var.vpc_id}"
  region = "${var.region}"
  cidr = "${var.cidr}"
  subnet_id_primary = "${var.subnet_id_primary}"
  subnet_id_secondary = "${var.subnet_id_secondary}"
  subnet_id_third = "${var.subnet_id_third}"
  subnet_cidr_primary = "${var.subnet_cidr_primary}"
  subnet_cidr_secondary = "${var.subnet_cidr_secondary}"
  subnet_cidr_third = "${var.subnet_cidr_third}"
}
