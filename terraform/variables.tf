variable "tenancy_ocid" { type = string }
variable "user_ocid" { type = string }
variable "fingerprint" { type = string }
variable "private_key" {
  type      = string
  sensitive = true
}
variable "region" { type = string }
variable "compartment_ocid" { type = string }
variable "external_port" { type = number }
