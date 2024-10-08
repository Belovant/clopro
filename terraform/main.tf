# Variables
variable "yc_token" {
  default = "t1.9euelZrLzMaVjYrOnomYjMzMx4zPmO3rnpWayYqej5KOk4mYl5mTkZqQnpfl8_daan9V-e8sc38F_t3z9xoZfVX57yxzfwX-zef1656VmomPx5nIipjIjo2XlpaSy4rO7_zF656VmomPx5nIipjIjo2XlpaSy4rO.pgaApK_YtInXG8c6qY8BCy-a-ETOm1fwCcgNw3lo4hAaHoyEtu1fL0USGEdiyjBWM7Xm3-NNEKK-WUvhVLUDCw"
}
variable "yc_cloud_id" {
  default = "b1gkjk5reuc4u9svu54m"
}
variable "yc_folder_id" {
  default = "b1gj45vv7fpc7kmc184h"
}
variable "yc_zone" {
  default = "ru-central1-a"
} 

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.yc_cloud_id
  folder_id = var.yc_folder_id
  zone = var.yc_zone
}

# Bucket
resource "yandex_iam_service_account" "sa-bucket" {
  name        = "sa-bucket"
}
resource "yandex_resourcemanager_folder_iam_member" "roleassignment-storageeditor" {
  folder_id = var.yc_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-bucket.id}"
}
resource "yandex_iam_service_account_static_access_key" "accesskey-bucket" {
  service_account_id = yandex_iam_service_account.sa-bucket.id
}
resource "yandex_kms_symmetric_key" "encryptkey" {
  name              = "encryptkey"
  default_algorithm = "AES_256"
}

resource "yandex_storage_bucket" "listopad-netology" {
  access_key = yandex_iam_service_account_static_access_key.accesskey-bucket.access_key
  secret_key = yandex_iam_service_account_static_access_key.accesskey-bucket.secret_key
  bucket     = "listopad-netology"
  default_storage_class = "STANDARD"
  acl           = "public-read"
  force_destroy = "true"
  anonymous_access_flags {
    read = true
    list = true
    config_read = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.encryptkey.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
resource "yandex_storage_object" "netology" {
  access_key = yandex_iam_service_account_static_access_key.accesskey-bucket.access_key
  secret_key = yandex_iam_service_account_static_access_key.accesskey-bucket.secret_key
  bucket     = yandex_storage_bucket.listopad-netology.id
  key        = "netology.png"
  source     = "netology.png"
}

# VPC
resource "yandex_vpc_network" "network-netology" {
  name = "network-netology"
}

output "picture_url" {
  value = "https://${yandex_storage_bucket.listopad-netology.bucket_domain_name}/${yandex_storage_object.netology.key}"
}

