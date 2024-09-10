resource "yandex_vpc_network" "network-1" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "subnet_public" {
  name           = "public"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = var.cidr_subnet_public
}
