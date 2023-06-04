module "ebc_csi_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name_prefix = "EBS-CSI-IRSA"

  attach_ebs_csi_policy = true
  ebs_csi_kms_cmk_ids   = module.ebs_kms_key.key_arn

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-node", "kube-system:ebs-csi-controller"]
    }
  }
}