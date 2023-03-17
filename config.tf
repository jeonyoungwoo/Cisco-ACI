################### Tenant #####################


# tenant 생성 (conmurph_intro_to_terraform)
resource "aci_tenant" "conmurph_intro_to_terraform" {
  name        = "conmurph_intro_to_terraform"    
}

# VRF 생성
resource "aci_vrf" "tera_vrf" {
  tenant_dn              = aci_tenant.conmurph_intro_to_terraform.id
  name                   = "tera_vrf"
 # description            = "from terraform"
 # annotation             = "tag_vrf"
  bd_enforced_enable     = "no"
  ip_data_plane_learning = "enabled"
  knw_mcast_act          = "permit"
  name_alias             = "alias_vrf"
  pc_enf_dir             = "ingress"
  pc_enf_pref            = "enforced"
  #relation_fv_rs_ctx_to_bgp_ctx_af_pol {
  #  af                     = "ipv4-ucast"
   # tn_bgp_ctx_af_pol_name = aci_bgp_address_family_context.example.id
 # }
}


# application profile 생성
resource "aci_application_profile" "myWebsite" {
  tenant_dn = "${aci_tenant.conmurph_intro_to_terraform.id}"  # application profile을 생성할 테넌트 입력
  name       = "my_website-ap"
}

# epg 생성 (web)
resource "aci_application_epg" "web" {  
    application_profile_dn  = "${aci_application_profile.myWebsite.id}"   # epg에 적용시킬 application profile 삽입
    name                            = "web"  #실제 생성될 epg name
    description                   = "this is the web epg created by terraform"
    flood_on_encap            = "disabled"
    fwd_ctrl                    = "none"
    has_mcast_source            = "no"
    match_t                         = "AtleastOne"
    name_alias                  = "web"
    pc_enf_pref                 = "unenforced"
    pref_gr_memb                = "exclude"
    prio                            = "unspecified"
    shutdown                    = "no"
	relation_fv_rs_bd       = aci_bridge_domain.bd_for_subnet.id   # epg에 BD 적용
  }
  
  
 /* # data 를 통해서도 생성가능 자세한 기능은 좀 더 살펴봐야함
  data "aci_application_epg" "app" {
  application_profile_dn  = aci_application_profile.myWebsite.id
  name                    = "app"
}
*/

resource "aci_application_epg" "app" {
    application_profile_dn  = "${aci_application_profile.myWebsite.id}"
    name                            = "app"
    description                   = "this is the app epg created by terraform"
    flood_on_encap            = "disabled"
    fwd_ctrl                    = "none"
    has_mcast_source            = "no"
    match_t                         = "AtleastOne"
    name_alias                  = "app"
    pc_enf_pref                 = "unenforced"
    pref_gr_memb                = "exclude"
    prio                            = "unspecified"
    shutdown                    = "no"
    relation_fv_rs_bd       = aci_bridge_domain.bd_for_subnet.id 
  }


resource "aci_application_epg" "db" {
    application_profile_dn  = "${aci_application_profile.myWebsite.id}"
    name                            = "db"
    description                   = "this is the database epg created by terraform"
    flood_on_encap            = "disabled"
    fwd_ctrl                    = "none"
    has_mcast_source            = "no"
    match_t                         = "AtleastOne"
    name_alias                  = "db"
    pc_enf_pref                 = "unenforced"
    pref_gr_memb                = "exclude"
    prio                            = "unspecified"
    shutdown                    = "no"
    relation_fv_rs_bd       = aci_bridge_domain.bd_for_subnet.id 
  }

# bridge domain 생성
resource "aci_bridge_domain" "bd_for_subnet" {
  tenant_dn   = "${aci_tenant.conmurph_intro_to_terraform.id}" # conmurph_intro_to_terraform 테넌트 안에 생성
  name        = "bd_for_subnet" # 실제 생성될 bd name
  description = "This bridge domain is created by the Terraform ACI provider" # 해당 리소스에 대한 설명
}

# subnet 생성 
resource "aci_subnet" "tera_subnet" {
  parent_dn                    = aci_bridge_domain.bd_for_subnet.id  #서브넷을 적용시킬 BD
  ip                                  = "172.16.1.1/24"   # 서브넷 ip
  #scope                               = "private"
  description                         = "This subject is created by Terraform v3"
}

# contract 생성
  resource "aci_contract" "tera_contract" {
        tenant_dn   = "${aci_tenant.conmurph_intro_to_terraform.id}" # contract을 생성할 테넌트 입력
        description = "From Terraform"
        name        = "tera_contract"
	  annotation  = "tag_contract"
    #    name_alias  = "alias_contract"
        prio        = "level1"
        scope       = "tenant"
        target_dscp = "unspecified"
    }


# contract을 epg에 적용
resource "aci_epg_to_contract" "tera_epg_contract" {
  application_epg_dn = "${aci_application_epg.web.id}"  # 적용시킬 epg 입력
  contract_dn        = "${aci_contract.tera_contract.id}" # 적용시킬 contract 입력
  contract_type      = "provider"
  annotation         = "tera_epg_contract"
  match_t            = "AtleastOne"
  prio               = "unspecified"
} 

# contract을 epg에 적용
resource "aci_epg_to_contract" "tera_epg_contract2" {
  application_epg_dn = "${aci_application_epg.web.id}"  # 적용시킬 epg 입력
  contract_dn        = "${aci_contract.tera_contract.id}" # 적용시킬 contract 입력
  contract_type      = "consumer"
  annotation         = "tera_epg_contract2"
  match_t            = "AtleastOne"
  prio               = "unspecified"
} 

# epg static port 생성
resource "aci_epg_to_static_path" "example" {
  application_epg_dn  = aci_application_epg.web.id
  tdn  = "topology/pod-1/paths-201/pathep-[eth1/3]"
  annotation = "annotation"
  encap  = "vlan-1000"
  instr_imedcy = "immediate"
  mode  = "regular"
  #primary_encap ="vlan-500"
}

 #contract subject 생성
 resource "aci_contract_subject" "tera_subject" {
        contract_dn   = aci_contract.tera_contract.id #적용시킬 contract 입력
        description   = "from terraform"
        name          = "tera_subject"
      #  annotation    = "tag_subject"
        cons_match_t  = "AtleastOne"
      #  name_alias    = "alias_subject"
        prio          = "level1"
        prov_match_t  = "AtleastOne"
        rev_flt_ports = "yes"
        target_dscp   = "CS0"
    }

# filter 생성
  resource "aci_filter" "tera_filter" {
        tenant_dn   = aci_tenant.conmurph_intro_to_terraform.id
        description = "From Terraform"
        name        = "tera_filter"
      #  annotation  = "tag_filter"
      #  name_alias  = "alias_filter"
    }

# filter entry 생성
        resource "aci_filter_entry" "tera_filter_entry" {
        filter_dn     = aci_filter.tera_filter.id
      #  description   = "From Terraform"
        name          = "tera_filter_entry"
       # annotation    = "tag_entry"
      #  apply_to_frag = "no"
      #  arp_opc       = "unspecified"
      #  d_from_port   = "unspecified"
      #  d_to_port     = "unspecified"
      #  ether_t       = "unspecified"
       # icmpv4_t      = "unspecified"
       # icmpv6_t      = "unspecified"
       # match_dscp    = "CS0"
       # name_alias    = "alias_entry"
       # prot          = "unspecified"
       # s_from_port   = "0"
      #  s_to_port     = "0"
      #  stateful      = "no"
      #  tcp_rules     = ["ack","rst"]
    }

# contract subject에 filter 적용
 resource "aci_contract_subject_filter" "tera_subject_filter" {
  contract_subject_dn  = aci_contract_subject.tera_subject.id
  filter_dn  = aci_filter.tera_filter.id
  action = "permit"
  directives = ["none"]
  priority_override = "default"
}

####################### Tenant Finish  ############################





####################### Fabric #####################################

#AAEP 생성
resource "aci_attachable_access_entity_profile" "tera_AAEP" {
  #description = "AAEP description"
  name        = "tera_AAEP"
 # annotation  = "tag_entity"
 # name_alias  = "alias_entity"
}

#AAEP에 L3 Domain 추가
/*resource "aci_aaep_to_domain" "foo_aaep_to_domain" {
  attachable_access_entity_profile_dn = aci_attachable_access_entity_profile.fooattachable_access_entity_profile.id
  domain_dn                           = aci_l3_domain_profile.fool3_domain_profile.id
}*/

# vlan pool 생성
resource "aci_vlan_pool" "tera_vlanpool" {
  name  = "tera_vlanpool"
  description = "From Terraform"
  alloc_mode  = "dynamic"
 # annotation  = "example"
  #name_alias  = "example"
}

# vlan pool range 생성
resource "aci_ranges" "tera_vlan_range" {
  vlan_pool_dn  = aci_vlan_pool.tera_vlanpool.id
  description   = "From Terraform"
  from          = "vlan-1"
  to            = "vlan-1000"
  alloc_mode    = "inherit"
 # annotation    = "example"
  name_alias    = "name_alias"
  role          = "external"
}

# physical domain 생성
resource "aci_physical_domain" "tera_physical_domain" {
  name        = "tera_physical_domain"
  #annotation  = "tag_domain"
  name_alias  = "alias_domain"
}

###############Fabric Finish ##############################################






# © junhyuk
