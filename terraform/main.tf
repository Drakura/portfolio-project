#Available Domain
data "oci_identity_availability_domains" "ads" { compartment_id = var.tenancy_ocid }

#Ubuntu Image Lookup
data "oci_core_images" "ubuntu" {
	compartment_id = var.compartment_ocid
	operating_system = "Canonical Ubuntu"
	operating_system_version = "22.04"
}

#Virtual Cloud Network (VCN)
resource "oci_core_vcn" "main" {
	compartment_id = var.compartment_ocid
	cidr_block = "10.0.0.0/16"
	display_name = "main-vcn"
}

#Subnet
resource "oci_core_subnet" "public" {
	compartment_id = var.compartment_ocid
	vcn_id = oci_core_vcn.main.id
	cidr_block = "10.0.1.0/24"
	display_name = "public-subnet"
	prohibit_public_ip_on_vnic = false
}

#Network Security Group (NSG)
resource "oci_core_network_security_group" "app_nsg" {
	compartment_id = var.compartment_ocid
	vcn_id = oci_core_vcn.main.id
	display_name = "app_nsg"
}

#Allow inbound traffic to my app port
resource "oci_core_network_security_group_security_rule" "allow_app" {
	network_security_group_id = oci_core_network_security_group.app_nsg.id
	direction = "INGRESS"
	protocol = "6" #TCP

	tcp_options {
		destination_port_range {
			min = var.external_port
			max = var.external_port
		}
	}

	source = "0.0.0.0/0"
}

#Compute Instance (VM)
resource "oci_core_instance" "vm" {
	compartment_id = var.compartment_ocid
        availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
        shape = "VM.Standard.A1.Flex"

        shape_config {
                ocpus = 1
                memory_in_gbs = 1
        }

        source_details {
                source_type = "image"
                image_id = data.oci_core_images.ubuntu.images[0].id
        }

        create_vnic_details {
                subnet_id = oci_core_subnet.public.id
                assign_public_ip = true
                nsg_ids = [oci_core_network_security_group.app_nsg.id]
        }

        metadata = {
                user_data = base64encode(
                        templatefile("${path.module}/cloud-init.sh", {
                                image_name = var.image_name
                                container_name = var.container_name
                                external_port = var.external_port
                        })
                )
        }

        display_name = "portfolio-app-vm"
}




