#configure provider with your cisco aci credentials or update with certificates
provider "aci" {
  username = var.apic_username # tfvars를 참조하는 apic_username 변수를 실제 aci username에 삽입 
  password = "${var.apic_password}" # tfvars를 참조하는 apic_password 변수를 실제 aci password에 삽입
  url      = "${var.apic_url}"  	# tfvars를 참조하는 apic_url 변수를 실제 aci url에 삽입
  insecure = true
}
