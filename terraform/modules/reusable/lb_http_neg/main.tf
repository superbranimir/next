locals {
  address = var.create_address ? join("", google_compute_global_address.default-global-address[*].address) : var.address

  url_map = var.create_url_map ? join("", google_compute_url_map.default-url-map[*].self_link) : var.url_map
}

### IPv4 block ###
resource "google_compute_global_forwarding_rule" "http-forwarding-rule" {
  name                  = var.name
  target                = google_compute_target_http_proxy.default-http-proxy.self_link
  ip_address            = local.address
  port_range            = var.http_port
  load_balancing_scheme = var.load_balancing_scheme
}

resource "google_compute_global_forwarding_rule" "https-forwarding-rule" {
  name                  = "${var.name}-https"
  target                = google_compute_target_https_proxy.default-https-proxy.self_link
  ip_address            = local.address
  port_range            = var.https_port
  load_balancing_scheme = var.load_balancing_scheme
}

resource "google_compute_global_address" "default-global-address" {
  count      = var.create_address ? 1 : 0
  name       = "${var.name}-address"
  ip_version = "IPV4"
}
### IPv4 block ###

# HTTP proxy when http forwarding is true
resource "google_compute_target_http_proxy" "default-http-proxy" {
  name    = "${var.name}-http-proxy"
  url_map = google_compute_url_map.https-redirect.self_link
}

# HTTPS proxy when ssl is true
data "google_compute_ssl_certificate" "ssl-certificate" {
  name = "${var.name}-cert"
}

resource "google_compute_target_https_proxy" "default-https-proxy" {
  name    = "${var.name}-https-proxy"
  url_map = local.url_map

  ssl_certificates            = [data.google_compute_ssl_certificate.ssl-certificate.self_link]
  ssl_policy                  = var.ssl_policy
  quic_override               = var.quic == null ? "NONE" : var.quic ? "ENABLE" : "DISABLE"
  server_tls_policy           = var.server_tls_policy
  http_keep_alive_timeout_sec = var.http_keep_alive_timeout_sec
}

resource "google_compute_url_map" "default-url-map" {
  count           = var.create_url_map ? 1 : 0
  name            = "${var.name}-url-map"
  default_service = google_compute_backend_service.default-backend-service[keys(var.backends)[0]].self_link
}

resource "google_compute_url_map" "https-redirect" {
  name = "${var.name}-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_backend_service" "default-backend-service" {
  for_each = var.backends

  project = coalesce(each.value["project"])
  name    = "${var.name}-backend-${each.key}"

  load_balancing_scheme = var.load_balancing_scheme

  port_name = lookup(each.value, "port_name", "http")
  protocol  = lookup(each.value, "protocol", "HTTP")

  description                     = lookup(each.value, "description", null)
  connection_draining_timeout_sec = lookup(each.value, "connection_draining_timeout_sec", null)
  enable_cdn                      = lookup(each.value, "enable_cdn", false)
  compression_mode                = lookup(each.value, "compression_mode", "DISABLED")
  custom_request_headers          = lookup(each.value, "custom_request_headers", [])
  custom_response_headers         = lookup(each.value, "custom_response_headers", [])
  session_affinity                = lookup(each.value, "session_affinity", null)
  affinity_cookie_ttl_sec         = lookup(each.value, "affinity_cookie_ttl_sec", null)
  locality_lb_policy              = lookup(each.value, "locality_lb_policy", null)


  # To achieve a null backend edge_security_policy, set each.value.edge_security_policy to "" (empty string), otherwise, it fallsback to var.edge_security_policy.
  edge_security_policy = each.value["edge_security_policy"] == "" ? null : (each.value["edge_security_policy"] == null ? var.edge_security_policy : each.value.edge_security_policy)

  # To achieve a null backend security_policy, set each.value.security_policy to "" (empty string), otherwise, it fallsback to var.security_policy.
  security_policy = each.value["security_policy"] == "" ? null : (each.value["security_policy"] == null ? var.security_policy : each.value.security_policy)

  dynamic "backend" {
    for_each = toset(each.value["groups"])
    content {
      description = lookup(backend.value, "description", null)
      group       = backend.value["group"]
    }
  }

  dynamic "log_config" {
    for_each = lookup(lookup(each.value, "log_config", {}), "enable", true) ? [1] : []
    content {
      enable      = lookup(lookup(each.value, "log_config", {}), "enable", true)
      sample_rate = lookup(lookup(each.value, "log_config", {}), "sample_rate", "1.0")
    }
  }

  dynamic "iap" {
    for_each = lookup(lookup(each.value, "iap_config", {}), "enable", false) ? [1] : []
    content {
      enabled              = lookup(lookup(each.value, "iap_config", {}), "enable", false)
      oauth2_client_id     = lookup(lookup(each.value, "iap_config", {}), "oauth2_client_id", "")
      oauth2_client_secret = lookup(lookup(each.value, "iap_config", {}), "oauth2_client_secret", "")
    }
  }

  dynamic "cdn_policy" {
    for_each = each.value.enable_cdn ? [1] : []
    content {
      cache_mode                   = each.value.cdn_policy.cache_mode
      signed_url_cache_max_age_sec = each.value.cdn_policy.signed_url_cache_max_age_sec
      default_ttl                  = each.value.cdn_policy.default_ttl
      max_ttl                      = each.value.cdn_policy.max_ttl
      client_ttl                   = each.value.cdn_policy.client_ttl
      negative_caching             = each.value.cdn_policy.negative_caching
      serve_while_stale            = each.value.cdn_policy.serve_while_stale

      dynamic "negative_caching_policy" {
        for_each = each.value.cdn_policy.negative_caching_policy != null ? [1] : []
        content {
          code = each.value.cdn_policy.negative_caching_policy.code
          ttl  = each.value.cdn_policy.negative_caching_policy.ttl
        }
      }

      dynamic "cache_key_policy" {
        for_each = each.value.cdn_policy.cache_key_policy != null ? [1] : []
        content {
          include_host           = each.value.cdn_policy.cache_key_policy.include_host
          include_protocol       = each.value.cdn_policy.cache_key_policy.include_protocol
          include_query_string   = each.value.cdn_policy.cache_key_policy.include_query_string
          query_string_blacklist = each.value.cdn_policy.cache_key_policy.query_string_blacklist
          query_string_whitelist = each.value.cdn_policy.cache_key_policy.query_string_whitelist
          include_http_headers   = each.value.cdn_policy.cache_key_policy.include_http_headers
          include_named_cookies  = each.value.cdn_policy.cache_key_policy.include_named_cookies
        }
      }

      dynamic "bypass_cache_on_request_headers" {
        for_each = toset(each.value.cdn_policy.bypass_cache_on_request_headers) != null ? each.value.cdn_policy.bypass_cache_on_request_headers : []
        content {
          header_name = bypass_cache_on_request_headers.value
        }
      }
    }
  }

  dynamic "outlier_detection" {
    for_each = each.value.outlier_detection != null && (var.load_balancing_scheme == "INTERNAL_SELF_MANAGED" || var.load_balancing_scheme == "EXTERNAL_MANAGED") ? [1] : []
    content {
      consecutive_errors                    = each.value.outlier_detection.consecutive_errors
      consecutive_gateway_failure           = each.value.outlier_detection.consecutive_gateway_failure
      enforcing_consecutive_errors          = each.value.outlier_detection.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = each.value.outlier_detection.enforcing_consecutive_gateway_failure
      enforcing_success_rate                = each.value.outlier_detection.enforcing_success_rate
      max_ejection_percent                  = each.value.outlier_detection.max_ejection_percent
      success_rate_minimum_hosts            = each.value.outlier_detection.success_rate_minimum_hosts
      success_rate_request_volume           = each.value.outlier_detection.success_rate_request_volume
      success_rate_stdev_factor             = each.value.outlier_detection.success_rate_stdev_factor

      dynamic "base_ejection_time" {
        for_each = each.value.outlier_detection.base_ejection_time != null ? [1] : []
        content {
          seconds = each.value.outlier_detection.base_ejection_time.seconds
          nanos   = each.value.outlier_detection.base_ejection_time.nanos
        }
      }

      dynamic "interval" {
        for_each = each.value.outlier_detection.interval != null ? [1] : []
        content {
          seconds = each.value.outlier_detection.interval.seconds
          nanos   = each.value.outlier_detection.interval.nanos
        }
      }
    }
  }
}
