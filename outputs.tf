################################################################################
# AWS
################################################################################

output "aws_vpc_id" {
  description = "AWS VPC ID"
  value       = aws_vpc.this.id
}

output "aws_ec2_instance_id" {
  description = "EC2 instance ID (use with SSM Session Manager)"
  value       = aws_instance.this.id
}

output "aws_ec2_private_ip" {
  description = "Private IP of EC2 instance (for cross-cloud connectivity test)"
  value       = aws_instance.this.private_ip
}

output "aws_vgw_id" {
  description = "VPN Gateway ID (attach to Direct Connect Gateway)"
  value       = aws_vpn_gateway.this.id
}

output "aws_dx_gateway_id" {
  description = "Direct Connect Gateway ID (use when creating Interconnect)"
  value       = aws_dx_gateway.this.id
}

################################################################################
# GCP
################################################################################

output "gcp_project_id" {
  description = "GCP project ID"
  value       = var.gcp_project_id
}

output "gcp_vpc_name" {
  description = "GCP VPC name"
  value       = google_compute_network.this.name
}

output "gcp_gce_name" {
  description = "GCE instance name (use with gcloud compute ssh --tunnel-through-iap)"
  value       = google_compute_instance.this.name
}

output "gcp_gce_zone" {
  description = "GCE instance zone"
  value       = google_compute_instance.this.zone
}

output "gcp_gce_internal_ip" {
  description = "Internal IP of GCE instance (for cross-cloud connectivity test)"
  value       = google_compute_instance.this.network_interface[0].network_ip
}

output "gcp_cloud_router_name" {
  description = "Cloud Router name (use when creating Transport)"
  value       = google_compute_router.this.name
}
