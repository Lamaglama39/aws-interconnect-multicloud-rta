################################################################################
# VPC
################################################################################

resource "google_compute_network" "this" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

################################################################################
# Subnet
################################################################################

resource "google_compute_subnetwork" "this" {
  name          = "${var.project_name}-subnet"
  ip_cidr_range = var.gcp_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.this.id
}

################################################################################
# Cloud Router - Interconnect multicloudで必要
################################################################################

resource "google_compute_router" "this" {
  name    = "${var.project_name}-router"
  region  = var.gcp_region
  network = google_compute_network.this.id

  bgp {
    asn = var.cloud_router_asn
  }
}

################################################################################
# Cloud NAT - 外部IPなしのGCEがインターネットにアクセスするために必要
################################################################################

resource "google_compute_router_nat" "this" {
  name                               = "${var.project_name}-nat"
  router                             = google_compute_router.this.name
  region                             = var.gcp_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

################################################################################
# Firewall Rules
################################################################################

# IAP経由のSSH用（gcloud compute ssh --tunnel-through-iap）
resource "google_compute_firewall" "iap_ssh" {
  name    = "${var.project_name}-allow-iap-ssh"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # IAP forwarding IP range
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["interconnect-test"]
}

# ICMP from AWS
resource "google_compute_firewall" "icmp_aws" {
  name    = "${var.project_name}-allow-icmp-aws"
  network = google_compute_network.this.name

  allow {
    protocol = "icmp"
  }

  source_ranges = [var.aws_vpc_cidr]
  target_tags   = ["interconnect-test"]
}

# HTTP from AWS
resource "google_compute_firewall" "http_aws" {
  name    = "${var.project_name}-allow-http-aws"
  network = google_compute_network.this.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [var.aws_vpc_cidr]
  target_tags   = ["interconnect-test"]
}

################################################################################
# GCE
################################################################################

resource "google_compute_instance" "this" {
  name         = "${var.project_name}-gce"
  machine_type = var.gcp_machine_type
  zone         = "${var.gcp_region}-a"
  tags         = ["interconnect-test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.this.id
    network_ip = var.gcp_gce_private_ip
    # 外部IPなし（IAP tunnel経由で接続）
  }

  # 疎通確認用にnginxをインストール、レスポンスでGCEと識別できるようにする
  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    echo "I'M GCE!!!" > /var/www/html/index.html
    systemctl enable --now nginx
  EOF
}
