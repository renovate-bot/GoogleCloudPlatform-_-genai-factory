# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Only used when ILBs are created.
# CA pools can't be recreated in the same project with the same name.
# This can be handy during experimentation
variable "ca_pool_name_suffix" {
  description = "The name suffix of the CA pool used for app ILB certificates."
  type        = string
  nullable    = false
  default     = "ca-pool-0"
}

variable "cloud_run_configs" {
  description = "The Cloud Run configurations."
  type = object({
    frontend = object({
      containers = optional(map(any), {
        frontend = {
          image = "us-docker.pkg.dev/cloudrun/container/hello"
          ports = {
            frontend = {
              container_port = 8080
            }
          }
        }
      })
      deletion_protection = optional(bool, true)
      ingress             = optional(string, "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER")
      max_instance_count  = optional(number, 3)
      service_invokers    = optional(list(string), [])
      vpc_access_egress   = optional(string, "ALL_TRAFFIC")
      vpc_access_tags     = optional(list(string), [])
    })
    ingestion = object({
      containers = optional(map(any), {
        ingestion = {
          image = "us-docker.pkg.dev/cloudrun/container/hello"
        }
      })
      deletion_protection = optional(bool, true)
      ingress             = optional(string, "INGRESS_TRAFFIC_INTERNAL_ONLY")
      max_instance_count  = optional(number, 3)
      service_invokers    = optional(list(string), [])
      vpc_access_egress   = optional(string, "ALL_TRAFFIC")
      vpc_access_tags     = optional(list(string), [])
    })
  })
  nullable = false
  default = {
    frontend  = {}
    ingestion = {}
  }
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection should be enabled."
  type        = bool
  nullable    = false
  default     = true
}

variable "ingestion_schedule_configs" {
  description = "The configuration of the Cloud Scheduler that calls invokes the Cloud Run ingestion job."
  type = object({
    attempt_deadline = optional(string, "60s")
    retry_count      = optional(number, 1)
    schedule         = optional(string, "*/30 * * * *")
  })
  nullable = false
  default  = {}
}

variable "lbs_config" {
  description = "The load balancers configuration."
  type = object({
    external = optional(object({
      enable = optional(bool, true)
      # The optional load balancer IP address.
      # If not specified, the module will create one.
      ip_address        = optional(string)
      domain            = optional(string, "example.com")
      allowed_ip_ranges = optional(list(string), ["0.0.0.0/0"])
    }), {})
    internal = optional(object({
      enable = optional(bool, false)
      # The optional load balancer IP address.
      # If not specified, the module will create one.
      ip_address        = optional(string)
      domain            = optional(string, "example.com")
      allowed_ip_ranges = optional(list(string), ["0.0.0.0/0"])
    }), {})
  })
  nullable = false
  default = {
    external = {}
    internal = {}
  }
}

variable "name" {
  description = "The name of the resources. This is also the project suffix if a new project is created."
  type        = string
  nullable    = false
  default     = "gf-rrag-search-0"
}

variable "networking_config" {
  description = "The networking configuration."
  type = object({
    create = optional(bool, true)
    vpc_id = optional(string, "net-0")
    subnet = optional(object({
      ip_cidr_range = optional(string, "10.0.0.0/24")
      name          = optional(string, "sub-0")
    }), {})
    subnet_proxy_only = optional(object({
      ip_cidr_range = optional(string, "10.20.0.0/24")
      name          = optional(string, "proxy-only-sub-0")
    }), {})
  })
  nullable = false
  default  = {}
}

variable "project_config" {
  description = "The project where to create the resources."
  type = object({
    id     = string
    number = string
    prefix = string
  })
  nullable = false
}

variable "region" {
  type        = string
  description = "The GCP region where to deploy the resources."
  nullable    = false
  default     = "europe-west1"
}

variable "service_accounts" {
  description = "The pre-created service accounts used by the blueprint."
  type = map(object({
    email     = string
    iam_email = string
    id        = string
  }))
  default = {}
}

variable "vector_search_config" {
  description = "The VertexAI index configuration."
  type = object({
    algorithm_config = optional(object({
      tree_ah_config = optional(object({
        leaf_node_embedding_count    = optional(number, 500)
        leaf_nodes_to_search_percent = optional(number, 7)
      }), {})
    }), {})
    approximate_neighbors_count = optional(number, 150)
    dimensions                  = optional(number, 768)
    distance_measure_type       = optional(string, "DOT_PRODUCT_DISTANCE")
    index_shard_size            = optional(string, "SHARD_SIZE_SMALL")
    index_update_method         = optional(string, "STREAM_UPDATE")
    # see https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vertex_ai_index_endpoint_deployed_index#dedicated_resources-1
    # for machine_type values and combo with index shard size.
    machine_type = optional(string, "e2-standard-2")
    # if not set, max_replica_count is set to min_replica_count
    max_replica_count = optional(number, 2)
    # min replica count 2 is set to provide SLA
    # see https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/vertex_ai_index_endpoint_deployed_index#min_replica_count-1
    min_replica_count = optional(number, 2)
  })
  nullable = false
  default  = {}
}
