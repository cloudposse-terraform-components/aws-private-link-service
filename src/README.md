---
tags:
  - component/private-link-service
  - layer/network
  - provider/aws
  - provider/terraform
---

# Component: `private-link-service`

This component provisions AWS VPC Endpoint Services (**provider side**) to expose **YOUR services** to external consumers via AWS PrivateLink.

## What This Component Does

**You are the PROVIDER** - This component creates the infrastructure to expose your services (EKS pods, RDS databases, APIs) to other AWS accounts or VPCs.

```
Your AWS Account (PROVIDER)              Consumer's AWS Account
┌─────────────────────────────┐         ┌──────────────────────────┐
│ Your Services               │         │ Their Applications       │
│ - EKS pods                  │         │ - Airflow (Astronomer)   │
│ - RDS databases             │         │ - External systems       │
│ - Internal APIs             │         │ - Partner services       │
│         ↓                   │         │         ↑                │
│ Network Load Balancer ──────┼─────────┼─────────┘                │
│         ↓                   │  AWS    │                          │
│ VPC Endpoint Service        │ Private │ VPC Endpoint             │
│ (this component)            │  Link   │ (they create)            │
│ com.amazonaws.vpce...       │         │                          │
└─────────────────────────────┘         └──────────────────────────┘
```

**Key Point**: The consumer (e.g., Astronomer) creates a VPC Endpoint in their account that connects to YOUR VPC Endpoint Service. Traffic flows privately over AWS's network, never touching the internet.

## Astronomer Integration

This example shows the full workflow for exposing your EKS services to Astronomer's Airflow cluster via PrivateLink.

### Architecture

```
Astronomer's AWS Account                    YOUR AWS Account
┌──────────────────────────┐               ┌─────────────────────────────────┐
│ Airflow Workers          │               │ EKS Cluster                     │
│ (run DAGs)               │               │                                 │
│        ↓                 │               │ Pods labeled:                   │
│ VPC Endpoint ────────────┼───Private─────┼→ astronomer: enabled            │
│ (Astronomer creates)     │    Link       │         ↓                       │
│                          │               │ NLB (eks/nlb component)         │
│                          │               │         ↓                       │
│                          │               │ VPC Endpoint Service            │
│                          │               │ (this component)                │
└──────────────────────────┘               └─────────────────────────────────┘
```

### Step 1: Label Your EKS Pods

First, tag the pods you want to expose to Astronomer:

```yaml
components:
  terraform:
    eks/echo-server:
      vars:
        # ...
        chart_values:
          labels:
            astronomer: enabled  # ← This label exposes pods to Astronomer
```

### Step 2: Create NLB via AWS Load Balancer Controller

Deploy an NLB that targets your labeled pods:

```yaml
components:
  terraform:
    eks/nlb/astronomer:
      metadata:
        component: eks/nlb
      vars:
        enabled: true
        name: "nlb"
        attributes: ["astronomer"]
        # Target pods with the astronomer label
        nlb_selector:
          astronomer: enabled
```

### Step 3: Create VPC Endpoint Service

Now expose the NLB via PrivateLink:

```yaml
components:
  terraform:
    private-link-service/astronomer:
      metadata:
        component: private-link-service
      vars:
        enabled: true
        name: "private-link-service"
        attributes: ["astronomer"]

        # Reference the NLB created in Step 2
        vpc_endpoint_service_network_load_balancer_arns:
          - !terraform.output eks/nlb/astronomer nlb_arn

        # Allow Astronomer's AWS account (get from their support)
        vpc_endpoint_service_allowed_principals:
          - "arn:aws:iam::ASTRONOMER-ACCOUNT-ID:role/astronomer-remote-management"
```

### Step 4: Share Service Name with Astronomer

Get the VPC Endpoint Service name:

```bash
vpc_endpoint_service_name = "com.amazonaws.vpce.us-west-2.vpce-svc-0abc123def456789"
```

<!-- prettier-ignore-start -->
<!-- prettier-ignore-end -->
## Usage

**Stack Level**: Regional

Here's an example snippet for how to use this component.

```yaml
components:
  terraform:
    private-link-service:
      vars:
        enabled: true  
        name: "private-link-service"

        vpc_endpoint_service_network_load_balancer_arns:
          - !terraform.output eks/nlb nlb_arn

        # Get customer AWS account ID or role ARN from their support team
        # Example (get from Astronomer support):
        vpc_endpoint_service_allowed_principals:
          - "arn:aws:iam::ASTRONOMER-ACCOUNT-ID:role/astronomer-remote-management"

```


<!-- markdownlint-disable -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_iam_roles"></a> [iam\_roles](#module\_iam\_roles) | ../account-map/modules/iam-roles | n/a |
| <a name="module_this"></a> [this](#module\_this) | cloudposse/label/null | 0.25.0 |

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic.endpoint_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_vpc_endpoint_connection_notification.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_connection_notification) | resource |
| [aws_vpc_endpoint_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service) | resource |
| [aws_vpc_endpoint_service_allowed_principal.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint_service_allowed_principal) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_tag_map"></a> [additional\_tag\_map](#input\_additional\_tag\_map) | Additional key-value pairs to add to each map in `tags_as_list_of_maps`. Not added to `tags` or `id`.<br/>This is for some rare cases where resources want additional configuration of tags<br/>and therefore take a list of maps with tag key, value, and additional configuration. | `map(string)` | `{}` | no |
| <a name="input_attributes"></a> [attributes](#input\_attributes) | ID element. Additional attributes (e.g. `workers` or `cluster`) to add to `id`,<br/>in the order they appear in the list. New attributes are appended to the<br/>end of the list. The elements of the list are joined by the `delimiter`<br/>and treated as a single ID element. | `list(string)` | `[]` | no |
| <a name="input_context"></a> [context](#input\_context) | Single object for setting entire context at once.<br/>See description of individual variables for details.<br/>Leave string and numeric variables as `null` to use default value.<br/>Individual variable settings (non-null) override settings in context object,<br/>except for attributes, tags, and additional\_tag\_map, which are merged. | `any` | <pre>{<br/>  "additional_tag_map": {},<br/>  "attributes": [],<br/>  "delimiter": null,<br/>  "descriptor_formats": {},<br/>  "enabled": true,<br/>  "environment": null,<br/>  "id_length_limit": null,<br/>  "label_key_case": null,<br/>  "label_order": [],<br/>  "label_value_case": null,<br/>  "labels_as_tags": [<br/>    "unset"<br/>  ],<br/>  "name": null,<br/>  "namespace": null,<br/>  "regex_replace_chars": null,<br/>  "stage": null,<br/>  "tags": {},<br/>  "tenant": null<br/>}</pre> | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to be used between ID elements.<br/>Defaults to `-` (hyphen). Set to `""` to use no delimiter at all. | `string` | `null` | no |
| <a name="input_descriptor_formats"></a> [descriptor\_formats](#input\_descriptor\_formats) | Describe additional descriptors to be output in the `descriptors` output map.<br/>Map of maps. Keys are names of descriptors. Values are maps of the form<br/>`{<br/>  format = string<br/>  labels = list(string)<br/>}`<br/>(Type is `any` so the map values can later be enhanced to provide additional options.)<br/>`format` is a Terraform format string to be passed to the `format()` function.<br/>`labels` is a list of labels, in order, to pass to `format()` function.<br/>Label values will be normalized before being passed to `format()` so they will be<br/>identical to how they appear in `id`.<br/>Default is `{}` (`descriptors` output will be empty). | `any` | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Set to false to prevent the module from creating any resources | `bool` | `null` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | ID element. Usually used for region e.g. 'uw2', 'us-west-2', OR role 'prod', 'staging', 'dev', 'UAT' | `string` | `null` | no |
| <a name="input_id_length_limit"></a> [id\_length\_limit](#input\_id\_length\_limit) | Limit `id` to this many characters (minimum 6).<br/>Set to `0` for unlimited length.<br/>Set to `null` for keep the existing setting, which defaults to `0`.<br/>Does not affect `id_full`. | `number` | `null` | no |
| <a name="input_label_key_case"></a> [label\_key\_case](#input\_label\_key\_case) | Controls the letter case of the `tags` keys (label names) for tags generated by this module.<br/>Does not affect keys of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper`.<br/>Default value: `title`. | `string` | `null` | no |
| <a name="input_label_order"></a> [label\_order](#input\_label\_order) | The order in which the labels (ID elements) appear in the `id`.<br/>Defaults to ["namespace", "environment", "stage", "name", "attributes"].<br/>You can omit any of the 6 labels ("tenant" is the 6th), but at least one must be present. | `list(string)` | `null` | no |
| <a name="input_label_value_case"></a> [label\_value\_case](#input\_label\_value\_case) | Controls the letter case of ID elements (labels) as included in `id`,<br/>set as tag values, and output by this module individually.<br/>Does not affect values of tags passed in via the `tags` input.<br/>Possible values: `lower`, `title`, `upper` and `none` (no transformation).<br/>Set this to `title` and set `delimiter` to `""` to yield Pascal Case IDs.<br/>Default value: `lower`. | `string` | `null` | no |
| <a name="input_labels_as_tags"></a> [labels\_as\_tags](#input\_labels\_as\_tags) | Set of labels (ID elements) to include as tags in the `tags` output.<br/>Default is to include all labels.<br/>Tags with empty values will not be included in the `tags` output.<br/>Set to `[]` to suppress all generated tags.<br/>**Notes:**<br/>  The value of the `name` tag, if included, will be the `id`, not the `name`.<br/>  Unlike other `null-label` inputs, the initial setting of `labels_as_tags` cannot be<br/>  changed in later chained modules. Attempts to change it will be silently ignored. | `set(string)` | <pre>[<br/>  "default"<br/>]</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | ID element. Usually the component or solution name, e.g. 'app' or 'jenkins'.<br/>This is the only ID element not also included as a `tag`.<br/>The "name" tag is set to the full `id` string. There is no tag with the value of the `name` input. | `string` | `null` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | ID element. Usually an abbreviation of your organization name, e.g. 'eg' or 'cp', to help ensure generated IDs are globally unique | `string` | `null` | no |
| <a name="input_regex_replace_chars"></a> [regex\_replace\_chars](#input\_regex\_replace\_chars) | Terraform regular expression (regex) string.<br/>Characters matching the regex will be removed from the ID elements.<br/>If not set, `"/[^a-zA-Z0-9-]/"` is used to remove all characters other than hyphens, letters and digits. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | n/a | yes |
| <a name="input_stage"></a> [stage](#input\_stage) | ID element. Usually used to indicate role, e.g. 'prod', 'staging', 'source', 'build', 'test', 'deploy', 'release' | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags (e.g. `{'BusinessUnit': 'XYZ'}`).<br/>Neither the tag keys nor the tag values will be modified by this module. | `map(string)` | `{}` | no |
| <a name="input_tenant"></a> [tenant](#input\_tenant) | ID element \_(Rarely used, not included by default)\_. A customer identifier, indicating who this instance of a resource is for | `string` | `null` | no |
| <a name="input_vpc_endpoint_service_acceptance_required"></a> [vpc\_endpoint\_service\_acceptance\_required](#input\_vpc\_endpoint\_service\_acceptance\_required) | Whether or not VPC endpoint connection requests to the service must be accepted by the service owner | `bool` | `true` | no |
| <a name="input_vpc_endpoint_service_allowed_principals"></a> [vpc\_endpoint\_service\_allowed\_principals](#input\_vpc\_endpoint\_service\_allowed\_principals) | List of ARNs of principals allowed to discover the VPC endpoint service | `list(string)` | `[]` | no |
| <a name="input_vpc_endpoint_service_gateway_load_balancer_arns"></a> [vpc\_endpoint\_service\_gateway\_load\_balancer\_arns](#input\_vpc\_endpoint\_service\_gateway\_load\_balancer\_arns) | List of Gateway Load Balancer ARNs to associate with the VPC endpoint service | `list(string)` | `[]` | no |
| <a name="input_vpc_endpoint_service_network_load_balancer_arns"></a> [vpc\_endpoint\_service\_network\_load\_balancer\_arns](#input\_vpc\_endpoint\_service\_network\_load\_balancer\_arns) | List of Network Load Balancer ARNs to associate with the VPC endpoint service | `list(string)` | `[]` | no |
| <a name="input_vpc_endpoint_service_private_dns_name"></a> [vpc\_endpoint\_service\_private\_dns\_name](#input\_vpc\_endpoint\_service\_private\_dns\_name) | Private DNS name for the VPC endpoint service | `string` | `null` | no |
| <a name="input_vpc_endpoint_service_supported_ip_address_types"></a> [vpc\_endpoint\_service\_supported\_ip\_address\_types](#input\_vpc\_endpoint\_service\_supported\_ip\_address\_types) | The supported IP address types. Valid values: ipv4, ipv6 | `list(string)` | <pre>[<br/>  "ipv4"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_events_sns_topic_arn"></a> [endpoint\_events\_sns\_topic\_arn](#output\_endpoint\_events\_sns\_topic\_arn) | The ARN of the SNS topic for endpoint connection events |
| <a name="output_vpc_endpoint_service_arn"></a> [vpc\_endpoint\_service\_arn](#output\_vpc\_endpoint\_service\_arn) | The ARN of the VPC endpoint service |
| <a name="output_vpc_endpoint_service_id"></a> [vpc\_endpoint\_service\_id](#output\_vpc\_endpoint\_service\_id) | The ID of the VPC endpoint service |
| <a name="output_vpc_endpoint_service_name"></a> [vpc\_endpoint\_service\_name](#output\_vpc\_endpoint\_service\_name) | The service name that consumers use to connect |
| <a name="output_vpc_endpoint_service_state"></a> [vpc\_endpoint\_service\_state](#output\_vpc\_endpoint\_service\_state) | The state of the VPC endpoint service |
<!-- markdownlint-restore -->



## References


- [AWS VPC Endpoint Services](https://docs.aws.amazon.com/vpc/latest/privatelink/create-endpoint-service.html) - Documentation for creating VPC Endpoint Services

- [AWS PrivateLink Documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/) - Official AWS PrivateLink documentation




[<img src="https://cloudposse.com/logo-300x69.svg" height="32" align="right"/>](https://cpco.io/homepage?utm_source=github&utm_medium=readme&utm_campaign=cloudposse-terraform-components/aws-private-link-service&utm_content=)
