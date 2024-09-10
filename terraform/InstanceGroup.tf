resource "yandex_iam_service_account" "sa-ig" {
  name = "sa-for-ig"
}

// Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "ig-editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-ig.id}"
}

// Саздание группы виртуальных машин
resource "yandex_compute_instance_group" "ig-1" {
  name = "ig-1"
  folder_id = var.folder_id
  service_account_id = yandex_iam_service_account.sa-ig.id

  instance_template {
    platform_id = "standard-v3"
    resources {
      memory = 2
      cores  = 2
    }

    boot_disk {
      mode = "READ_WRITE"
      initialize_params {
        image_id = var.lamp-instance-image-id
      }
    }

    network_interface {
      network_id = yandex_vpc_network.network-1.id
      subnet_ids = [yandex_vpc_subnet.subnet_public.id]
      nat = true
    }

    scheduling_policy {
        preemptible = true  // Прерываемая
    }
    
    metadata = {
      ssh-keys = "ubuntu:${var.public_key}"
      user-data = <<EOF
#!/bin/bash
apt install httpd -y
cd /var/www/html
echo '<html><img src="http://${yandex_storage_bucket.test.bucket_domain_name}/picture.jpg"/></html>' > index.html
service httpd start
EOF  
    }
  }
  
  scale_policy {
    fixed_scale {
      size = 3
    }
  }
  allocation_policy {
    zones = [var.default_zone]
  }
  deploy_policy {
    max_unavailable = 1
    max_creating = 3
    max_expansion = 1
    max_deleting = 1
    startup_duration = 3
  }
    health_check {
        http_options {
            port    = 80
            path    = "/"
        }
    }

    depends_on = [
        yandex_storage_bucket.netology-bucket
    ]  
}
