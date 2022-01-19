resource "kubernetes_manifest" "ingress_route" {
  manifest = {
    "apiVersion" = "apiextensions.k8s.io/v1"
    "kind" = "CustomResourceDefinition"
    "metadata" = {
      "annotations" = {
        "controller-gen.kubebuilder.io/version" = "v0.6.2"
      }
      "creationTimestamp" = null
      "name" = "ingressroutes.traefik.containo.us"
    }
    "spec" = {
      "group" = "traefik.containo.us"
      "names" = {
        "kind" = "IngressRoute"
        "listKind" = "IngressRouteList"
        "plural" = "ingressroutes"
        "singular" = "ingressroute"
      }
      "scope" = "Namespaced"
      "versions" = [
        {
          "name" = "v1alpha1"
          "schema" = {
            "openAPIV3Schema" = {
              "description" = "IngressRoute is an Ingress CRD specification."
              "properties" = {
                "apiVersion" = {
                  "description" = "APIVersion defines the versioned schema of this representation of an object. Servers should convert recognized schemas to the latest internal value, and may reject unrecognized values. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#resources"
                  "type" = "string"
                }
                "kind" = {
                  "description" = "Kind is a string value representing the REST resource this object represents. Servers may infer this from the endpoint the client submits requests to. Cannot be updated. In CamelCase. More info: https://git.k8s.io/community/contributors/devel/sig-architecture/api-conventions.md#types-kinds"
                  "type" = "string"
                }
                "metadata" = {
                  "type" = "object"
                }
                "spec" = {
                  "description" = "IngressRouteSpec is a specification for a IngressRouteSpec resource."
                  "properties" = {
                    "entryPoints" = {
                      "items" = {
                        "type" = "string"
                      }
                      "type" = "array"
                    }
                    "routes" = {
                      "items" = {
                        "description" = "Route contains the set of routes."
                        "properties" = {
                          "kind" = {
                            "enum" = [
                              "Rule",
                            ]
                            "type" = "string"
                          }
                          "match" = {
                            "type" = "string"
                          }
                          "middlewares" = {
                            "items" = {
                              "description" = "MiddlewareRef is a ref to the Middleware resources."
                              "properties" = {
                                "name" = {
                                  "type" = "string"
                                }
                                "namespace" = {
                                  "type" = "string"
                                }
                              }
                              "required" = [
                                "name",
                              ]
                              "type" = "object"
                            }
                            "type" = "array"
                          }
                          "priority" = {
                            "type" = "integer"
                          }
                          "services" = {
                            "items" = {
                              "description" = "Service defines an upstream to proxy traffic."
                              "properties" = {
                                "kind" = {
                                  "enum" = [
                                    "Service",
                                    "TraefikService",
                                  ]
                                  "type" = "string"
                                }
                                "name" = {
                                  "description" = "Name is a reference to a Kubernetes Service object (for a load-balancer of servers), or to a TraefikService object (service load-balancer, mirroring, etc). The differentiation between the two is specified in the Kind field."
                                  "type" = "string"
                                }
                                "namespace" = {
                                  "type" = "string"
                                }
                                "passHostHeader" = {
                                  "type" = "boolean"
                                }
                                "port" = {
                                  "anyOf" = [
                                    {
                                      "type" = "integer"
                                    },
                                    {
                                      "type" = "string"
                                    },
                                  ]
                                  "x-kubernetes-int-or-string" = true
                                }
                                "responseForwarding" = {
                                  "description" = "ResponseForwarding holds configuration for the forward of the response."
                                  "properties" = {
                                    "flushInterval" = {
                                      "type" = "string"
                                    }
                                  }
                                  "type" = "object"
                                }
                                "scheme" = {
                                  "type" = "string"
                                }
                                "serversTransport" = {
                                  "type" = "string"
                                }
                                "sticky" = {
                                  "description" = "Sticky holds the sticky configuration."
                                  "properties" = {
                                    "cookie" = {
                                      "description" = "Cookie holds the sticky configuration based on cookie."
                                      "properties" = {
                                        "httpOnly" = {
                                          "type" = "boolean"
                                        }
                                        "name" = {
                                          "type" = "string"
                                        }
                                        "sameSite" = {
                                          "type" = "string"
                                        }
                                        "secure" = {
                                          "type" = "boolean"
                                        }
                                      }
                                      "type" = "object"
                                    }
                                  }
                                  "type" = "object"
                                }
                                "strategy" = {
                                  "type" = "string"
                                }
                                "weight" = {
                                  "description" = "Weight should only be specified when Name references a TraefikService object (and to be precise, one that embeds a Weighted Round Robin)."
                                  "type" = "integer"
                                }
                              }
                              "required" = [
                                "name",
                              ]
                              "type" = "object"
                            }
                            "type" = "array"
                          }
                        }
                        "required" = [
                          "kind",
                          "match",
                        ]
                        "type" = "object"
                      }
                      "type" = "array"
                    }
                    "tls" = {
                      "description" = <<-EOT
                      TLS contains the TLS certificates configuration of the routes. To enable Let's Encrypt, use an empty TLS struct, e.g. in YAML: 
                       	 tls: {} # inline format 
                       	 tls: 	   secretName: # block format
                      EOT
                      "properties" = {
                        "certResolver" = {
                          "type" = "string"
                        }
                        "domains" = {
                          "items" = {
                            "description" = "Domain holds a domain name with SANs."
                            "properties" = {
                              "main" = {
                                "type" = "string"
                              }
                              "sans" = {
                                "items" = {
                                  "type" = "string"
                                }
                                "type" = "array"
                              }
                            }
                            "type" = "object"
                          }
                          "type" = "array"
                        }
                        "options" = {
                          "description" = "Options is a reference to a TLSOption, that specifies the parameters of the TLS connection."
                          "properties" = {
                            "name" = {
                              "type" = "string"
                            }
                            "namespace" = {
                              "type" = "string"
                            }
                          }
                          "required" = [
                            "name",
                          ]
                          "type" = "object"
                        }
                        "secretName" = {
                          "description" = "SecretName is the name of the referenced Kubernetes Secret to specify the certificate details."
                          "type" = "string"
                        }
                        "store" = {
                          "description" = "Store is a reference to a TLSStore, that specifies the parameters of the TLS store."
                          "properties" = {
                            "name" = {
                              "type" = "string"
                            }
                            "namespace" = {
                              "type" = "string"
                            }
                          }
                          "required" = [
                            "name",
                          ]
                          "type" = "object"
                        }
                      }
                      "type" = "object"
                    }
                  }
                  "required" = [
                    "routes",
                  ]
                  "type" = "object"
                }
              }
              "required" = [
                "metadata",
                "spec",
              ]
              "type" = "object"
            }
          }
          "served" = true
          "storage" = true
        },
      ]
    }

  }
}

resource "kubernetes_manifest" "ingress_route_tcp" {

  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind       = "CustomResourceDefinition"
    metadata = {
      name = "ingressroutetcps.traefik.containo.us"
    }
    spec = {
      group = "traefik.containo.us"
      names = {
        kind     = "IngressRouteTCP"
        plural   = "ingressroutetcps"
        singular = "ingressroutetcp"
      }
      scope = "Namespaced"
      versions = [
        {
          name    = "v1alpha1"
          served  = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    routes = {
                      type = "array"
                      items = {
                        type = "object"
                        properties = {
                          match = {
                            type = "string"
                          }
                          services = {
                            type = "array"
                            items = {
                              type     = "object"
                              required = ["name", "port"]
                              properties = {
                                name = {
                                  type = "string"
                                }
                                namespace = {
                                  type = "string"
                                }
                                port = {
                                  x-kubernetes-int-or-string = true
                                  pattern                    = "^[1-9]\\d*$"
                                }
                                weight = {
                                  type = "integer"
                                }
                                terminationDelay = {
                                  type = "integer"
                                }
                                proxyProtocol = {
                                  type     = "object"
                                  required = ["version"]
                                  properties = {
                                    version = {
                                      type    = "integer"
                                      minimum = 1
                                      maximum = 2
                                    }
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                    entryPoints = {
                      type = "array"
                      items = {
                        type = "string"
                      }
                    }
                    tls = {
                      type = "object"
                      properties = {
                        secretName = {
                          type = "string"
                        }
                        passthrough = {
                          type = "boolean"
                        }
                        options = {
                          type     = "object"
                          required = ["name", "namespace"]
                          properties = {
                            name = {
                              type = "string"
                            }
                            namespace = {
                              type = "string"
                            }
                          }
                        }
                        store = {
                          type     = "object"
                          required = ["name", "namespace"]
                          properties = {
                            name = {
                              type = "string"
                            }
                            namespace = {
                              type = "string"
                            }
                          }
                        }
                        certResolver = {
                          type = "string"
                        }
                        domains = {
                          type = "array"
                          items = {
                            type     = "object"
                            required = ["main"]
                            properties = {
                              main = {
                                type = "string"
                              }
                              sans = {
                                type = "array"
                                items = {
                                  type = "string"
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "ingress_route_udp" {

  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind       = "CustomResourceDefinition"
    metadata = {
      name = "ingressrouteudps.traefik.containo.us"
    }
    spec = {
      group = "traefik.containo.us"
      names = {
        kind     = "IngressRouteUDP"
        plural   = "ingressrouteudps"
        singular = "ingressrouteudp"
      }
      scope = "Namespaced"
      versions = [
        {
          name    = "v1alpha1"
          served  = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    routes = {
                      type = "array"
                      items = {
                        type = "object"
                        properties = {
                          services = {
                            type = "array"
                            items = {
                              type     = "object"
                              required = ["name"]
                              properties = {
                                name = {
                                  type = "string"
                                }
                                namespace = {
                                  type = "string"
                                }
                                port = {
                                  x-kubernetes-int-or-string = true
                                  pattern                    = "^[1-9]\\d*$"
                                }
                                weight = {
                                  type = "integer"
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                    entryPoints = {
                      type = "array"
                      items = {
                        type = "string"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "middleware" {

  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind       = "CustomResourceDefinition"
    metadata = {
      name = "middlewares.traefik.containo.us"
    }
    spec = {
      group = "traefik.containo.us"
      names = {
        kind     = "Middleware"
        plural   = "middlewares"
        singular = "middleware"
      }
      scope = "Namespaced"
      versions = [
        {
          name    = "v1alpha1"
          served  = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    addPrefix = {
                      type = "object"
                      properties = {
                        prefix = {
                          type = "string"
                        }
                      }
                    }
                    stripPrefix = {
                      type = "object"
                      properties = {
                        prefixes = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        forceSlash = {
                          type = "boolean"
                        }
                      }
                    }
                    stripPrefixRegex = {
                      type = "object"
                      properties = {
                        regex = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                      }
                    }
                    replacePath = {
                      type = "object"
                      properties = {
                        path = {
                          type = "string"
                        }
                      }
                    }
                    replacePathRegex = {
                      type = "object"
                      properties = {
                        regex = {
                          type = "string"
                        }
                        replacement = {
                          type = "string"
                        }
                      }
                    }
                    chain = {
                      type = "object"
                      properties = {
                        middlewares = {
                          type = "array"
                          items = {
                            type     = "object"
                            required = ["name", "namespace"]
                            properties = {
                              name = {
                                type = "string"
                              }
                              namespace = {
                                type = "string"
                              }
                            }
                          }
                        }
                      }
                    }
                    ipWhiteList = {
                      type = "object"
                      properties = {
                        sourceRange = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        ipStrategy = {
                          type = "object"
                          properties = {
                            depth = {
                              type = "integer"
                            }
                            excludedIPs = {
                              type = "array"
                              items = {
                                type = "string"
                              }
                            }
                          }
                        }
                      }
                    }
                    headers = {
                      type = "object"
                      properties = {
                        customRequestHeaders = {
                          type = "object"
                        }
                        customResponseHeaders = {
                          type = "object"
                        }
                        accessControlAllowCredentials = {
                          type = "boolean"
                        }
                        accessControlAllowHeaders = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        accessControlAllowMethods = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        accessControlAllowOrigin = {
                          type = "string"
                        }
                        accessControlAllowOriginList = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        accessControlExposeHeaders = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        accessControlMaxAge = {
                          type = "integer"
                        }
                        addVaryHeader = {
                          type = "boolean"
                        }
                        allowedHosts = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        hostsProxyHeaders = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        sslRedirect = {
                          type = "boolean"
                        }
                        sslTemporaryRedirect = {
                          type = "boolean"
                        }
                        sslHost = {
                          type = "string"
                        }
                        sslProxyHeaders = {
                          type = "object"
                        }
                        sslForceHost = {
                          type = "boolean"
                        }
                        stsSeconds = {
                          type = "integer"
                        }
                        stsIncludeSubdomains = {
                          type = "boolean"
                        }
                        stsPreload = {
                          type = "boolean"
                        }
                        forceSTSheader = {
                          type = "boolean"
                        }
                        frameDeny = {
                          type = "boolean"
                        }
                        customFrameOptionsValue = {
                          type = "string"
                        }
                        contentTypeNosniff = {
                          type = "boolean"
                        }
                        browserXssFilter = {
                          type = "boolean"
                        }
                        customBrowserXSSValue = {
                          type = "string"
                        }
                        contentSecurityPolicy = {
                          type = "string"
                        }
                        publicKey = {
                          type = "string"
                        }
                        referrerPolicy = {
                          type = "string"
                        }
                        featurePolicy = {
                          type = "string"
                        }
                        isDevelopment = {
                          type = "boolean"
                        }
                      }
                    }
                    errors = {
                      type = "object"
                      properties = {
                        status = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        service = {
                          type = "object"
                          properties = {
                            sticky = {
                              type = "object"
                              properties = {
                                cookie = {
                                  type = "object"
                                  properties = {
                                    name = {
                                      type = "string"
                                    }
                                    secure = {
                                      type = "boolean"
                                    }
                                    httpOnly = {
                                      type = "boolean"
                                    }
                                  }
                                }
                              }
                            }
                            namespace = {
                              type = "string"
                            }
                            kind = {
                              type = "string"
                            }
                            name = {
                              type = "string"
                            }
                            weight = {
                              type = "integer"
                            }
                            responseForwarding = {
                              type = "object"
                              properties = {
                                flushInterval = {
                                  type = "string"
                                }
                              }
                            }
                            passHostHeader = {
                              type = "boolean"
                            }
                            healthCheck = {
                              type = "object"
                              properties = {
                                path = {
                                  type = "string"
                                }
                                host = {
                                  type = "string"
                                }
                                scheme = {
                                  type = "string"
                                }
                                intervalSeconds = {
                                  type = "integer"
                                }
                                timeoutSeconds = {
                                  type = "integer"
                                }
                                headers = {
                                  type = "object"
                                }
                              }
                            }
                            strategy = {
                              type = "string"
                            }
                            scheme = {
                              type = "string"
                            }
                            port = {
                              type = "integer"
                            }
                          }
                        }
                        query = {
                          type = "string"
                        }
                      }
                    }
                    rateLimit = {
                      type = "object"
                      properties = {
                        average = {
                          type = "integer"
                        }
                        burst = {
                          type = "integer"
                        }
                        sourceCriterion = {
                          type = "object"
                          properties = {
                            ipStrategy = {
                              type = "object"
                              properties = {
                                depth = {
                                  type = "integer"
                                }
                                excludedIPs = {
                                  type = "array"
                                  items = {
                                    type = "string"
                                  }
                                }
                              }
                            }
                            requestHeaderName = {
                              type = "string"
                            }
                            requestHost = {
                              type = "boolean"
                            }
                          }
                        }
                      }
                    }
                    redirectRegex = {
                      type = "object"
                      properties = {
                        regex = {
                          type = "string"
                        }
                        replacement = {
                          type = "string"
                        }
                        permanent = {
                          type = "boolean"
                        }
                      }
                    }
                    redirectScheme = {
                      type = "object"
                      properties = {
                        scheme = {
                          type = "string"
                        }
                        port = {
                          type = "string"
                        }
                        permanent = {
                          type = "boolean"
                        }
                      }
                    }
                    basicAuth = {
                      type = "object"
                      properties = {
                        secret = {
                          type = "string"
                        }
                        realm = {
                          type = "string"
                        }
                        removeHeader = {
                          type = "boolean"
                        }
                        headerField = {
                          type = "string"
                        }
                      }
                    }
                    digestAuth = {
                      type = "object"
                      properties = {
                        secret = {
                          type = "string"
                        }
                        removeHeader = {
                          type = "boolean"
                        }
                        realm = {
                          type = "string"
                        }
                        headerField = {
                          type = "string"
                        }
                      }
                    }
                    forwardAuth = {
                      type = "object"
                      properties = {
                        address = {
                          type = "string"
                        }
                        trustForwardHeader = {
                          type = "boolean"
                        }
                        authResponseHeaders = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        tls = {
                          type = "object"
                          properties = {
                            caSecret = {
                              type = "string"
                            }
                            caOptional = {
                              type = "boolean"
                            }
                            certSecret = {
                              type = "string"
                            }
                            insecureSkipVerify = {
                              type = "boolean"
                            }
                          }
                        }
                      }
                    }
                    inFlightReq = {
                      type = "object"
                      properties = {
                        amount = {
                          type = "integer"
                        }
                        sourceCriterion = {
                          type = "object"
                          properties = {
                            ipStrategy = {
                              type = "object"
                              properties = {
                                depth = {
                                  type = "integer"
                                }
                                excludedIPs = {
                                  type = "array"
                                  items = {
                                    type = "string"
                                  }
                                }
                              }
                            }
                            requestHeaderName = {
                              type = "string"
                            }
                            requestHost = {
                              type = "boolean"
                            }
                          }
                        }
                      }
                    }
                    buffering = {
                      type = "object"
                      properties = {
                        maxRequestBodyBytes = {
                          type = "integer"
                        }
                        memRequestBodyBytes = {
                          type = "integer"
                        }
                        maxResponseBodyBytes = {
                          type = "integer"
                        }
                        memResponseBodyBytes = {
                          type = "integer"
                        }
                        retryExpression = {
                          type = "string"
                        }
                      }
                    }
                    circuitBreaker = {
                      type = "object"
                      properties = {
                        expression = {
                          type = "string"
                        }
                      }
                    }
                    compress = {
                      type = "object"
                      properties = {
                        excludedContentTypes = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                      }
                    }
                    passTLSClientCert = {
                      type = "object"
                      properties = {
                        pem = {
                          type = "boolean"
                        }
                        info = {
                          type = "object"
                          properties = {
                            notAfter = {
                              type = "boolean"
                            }
                            notBefore = {
                              type = "boolean"
                            }
                            sans = {
                              type = "boolean"
                            }
                            subject = {
                              type = "object"
                              properties = {
                                country = {
                                  type = "boolean"
                                }
                                province = {
                                  type = "boolean"
                                }
                                locality = {
                                  type = "boolean"
                                }
                                organization = {
                                  type = "boolean"
                                }
                                commonName = {
                                  type = "boolean"
                                }
                                serialNumber = {
                                  type = "boolean"
                                }
                                domainComponent = {
                                  type = "boolean"
                                }
                              }
                            }
                            issuer = {
                              type = "object"
                              properties = {
                                country = {
                                  type = "boolean"
                                }
                                province = {
                                  type = "boolean"
                                }
                                locality = {
                                  type = "boolean"
                                }
                                organization = {
                                  type = "boolean"
                                }
                                commonName = {
                                  type = "boolean"
                                }
                                serialNumber = {
                                  type = "boolean"
                                }
                                domainComponent = {
                                  type = "boolean"
                                }
                              }
                            }
                            serialNumber = {
                              type = "boolean"
                            }
                          }
                        }
                      }
                    }
                    retry = {
                      type = "object"
                      properties = {
                        attempts = {
                          type = "integer"
                        }
                      }
                    }
                    contentType = {
                      type = "object"
                      properties = {
                        autoDetect = {
                          type = "boolean"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "serverstransports" {

  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind       = "CustomResourceDefinition"
    metadata = {
      name = "serverstransports.traefik.containo.us"
    }
    spec = {
      group = "traefik.containo.us"
      names = {
        kind     = "ServersTransport"
        plural   = "serverstransports"
        singular = "serverstransports"
      }
      scope = "Namespaced"
      versions = [
        {
          name    = "v1alpha1"
          served  = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    serverName = {
                      type = "string"
                    }
                    insecureSkipVerify = {
                      type = "boolean"
                    }
                    rootCAsSecrets = {
                      type = "array"
                      items = {
                        type = "string"
                      }
                    }
                    certificatesSecrets = {
                      type = "array"
                      items = {
                        type = "string"
                      }
                    }
                    maxIdleConnsPerHost = {
                      type = "integer"
                    }
                    forwardingTimeouts = {
                      type = "object"
                      properties = {
                        dialTimeout = {
                          x-kubernetes-int-or-string = true
                          pattern                    = "^[1-9](\\d+)?(ns|us|µs|μs|ms|s|m|h)?$"
                        }
                        responseHeaderTimeout = {
                          x-kubernetes-int-or-string = true
                          pattern                    = "^[1-9](\\d+)?(ns|us|µs|μs|ms|s|m|h)?$"
                        }
                        idleConnTimeout = {
                          x-kubernetes-int-or-string = true
                          pattern                    = "^[1-9](\\d+)?(ns|us|µs|μs|ms|s|m|h)?$"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "tls_option" {

  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind       = "CustomResourceDefinition"
    metadata = {
      name = "tlsoptions.traefik.containo.us"
    }
    spec = {
      group = "traefik.containo.us"
      names = {
        kind     = "TLSOption"
        plural   = "tlsoptions"
        singular = "tlsoption"
      }
      scope = "Namespaced"
      versions = [
        {
          name    = "v1alpha1"
          served  = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    minVersion = {
                      type = "string"
                    }
                    maxVersion = {
                      type = "string"
                    }
                    cipherSuites = {
                      type = "array"
                      items = {
                        type = "string"
                      }
                    }
                    curvePreferences = {
                      type = "array"
                      items = {
                        type = "string"
                      }
                    }
                    clientAuth = {
                      type = "object"
                      properties = {
                        clientAuthType = {
                          type = "string"
                          enum = ["NoClientCert", "RequestClientCert", "VerifyClientCertIfGiven", "RequireAndVerifyClientCert"]
                        }
                        secretNames = {
                          type = "array"
                          items = {
                            type = "string"
                          }
                        }
                        sniStrict = {
                          type = "boolean"
                        }
                        preferServerCipherSuites = {
                          type = "boolean"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "tls_stores" {

  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind       = "CustomResourceDefinition"
    metadata = {
      name = "tlsstores.traefik.containo.us"
    }
    spec = {
      group = "traefik.containo.us"
      names = {
        kind     = "TLSStore"
        plural   = "tlsstores"
        singular = "tlsstore"
      }
      scope = "Namespaced"
      versions = [
        {
          name    = "v1alpha1"
          served  = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    defaultCertificate = {
                      type = "object"
                      properties = {
                        secretName = {
                          type = "string"
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}


resource "kubernetes_manifest" "traefik_service" {

  manifest = {
    apiVersion = "apiextensions.k8s.io/v1"
    kind       = "CustomResourceDefinition"
    metadata = {
      name = "traefikservices.traefik.containo.us"
    }
    spec = {
      group = "traefik.containo.us"
      names = {
        kind     = "TraefikService"
        plural   = "traefikservices"
        singular = "traefikservice"
      }
      scope = "Namespaced"
      versions = [
        {
          name    = "v1alpha1"
          served  = true
          storage = true
          schema = {
            openAPIV3Schema = {
              type = "object"
              properties = {
                spec = {
                  type = "object"
                  properties = {
                    weighted = {
                      type = "object"
                      properties = {
                        services = {
                          type = "array"
                          items = {
                            type = "object"
                            properties = {
                              sticky = {
                                type = "object"
                                properties = {
                                  cookie = {
                                    type = "object"
                                    properties = {
                                      name = {
                                        type = "string"
                                      }
                                      secure = {
                                        type = "boolean"
                                      }
                                      httpOnly = {
                                        type = "boolean"
                                      }
                                    }
                                  }
                                }
                              }
                              namespace = {
                                type = "string"
                              }
                              kind = {
                                type = "string"
                              }
                              name = {
                                type = "string"
                              }
                              weight = {
                                type = "integer"
                              }
                              responseForwarding = {
                                type = "object"
                                properties = {
                                  flushInterval = {
                                    type = "string"
                                  }
                                }
                              }
                              passHostHeader = {
                                type = "boolean"
                              }
                              healthCheck = {
                                type = "object"
                                properties = {
                                  path = {
                                    type = "string"
                                  }
                                  host = {
                                    type = "string"
                                  }
                                  scheme = {
                                    type = "string"
                                  }
                                  intervalSeconds = {
                                    type = "integer"
                                  }
                                  timeoutSeconds = {
                                    type = "integer"
                                  }
                                  headers = {
                                    type = "object"
                                  }
                                }
                              }
                              strategy = {
                                type = "string"
                              }
                              scheme = {
                                type = "string"
                              }
                              port = {
                                type = "integer"
                              }
                            }
                          }
                        }
                        sticky = {
                          type = "object"
                          properties = {
                            cookie = {
                              type = "object"
                              properties = {
                                name = {
                                  type = "string"
                                }
                                secure = {
                                  type = "boolean"
                                }
                                httpOnly = {
                                  type = "boolean"
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                    mirroring = {
                      type = "object"
                      properties = {
                        weight = {
                          type = "integer"
                        }
                        responseForwarding = {
                          type = "object"
                          properties = {
                            flushInterval = {
                              type = "string"
                            }
                          }
                        }
                        passHostHeader = {
                          type = "boolean"
                        }
                        healthCheck = {
                          type = "object"
                          properties = {
                            path = {
                              type = "string"
                            }
                            host = {
                              type = "string"
                            }
                            scheme = {
                              type = "string"
                            }
                            intervalSeconds = {
                              type = "integer"
                            }
                            timeoutSeconds = {
                              type = "integer"
                            }
                            headers = {
                              type = "object"
                            }
                          }
                        }
                        strategy = {
                          type = "string"
                        }
                        scheme = {
                          type = "string"
                        }
                        port = {
                          type = "integer"
                        }
                        sticky = {
                          type = "object"
                          properties = {
                            cookie = {
                              type = "object"
                              properties = {
                                name = {
                                  type = "string"
                                }
                                secure = {
                                  type = "boolean"
                                }
                                httpOnly = {
                                  type = "boolean"
                                }
                              }
                            }
                          }
                        }
                        namespace = {
                          type = "string"
                        }
                        kind = {
                          type = "string"
                        }
                        name = {
                          type = "string"
                        }
                        mirrors = {
                          type = "array"
                          items = {
                            type = "object"
                            properties = {
                              name = {
                                type = "string"
                              }
                              kind = {
                                type = "string"
                              }
                              namespace = {
                                type = "string"
                              }
                              sticky = {
                                type = "object"
                                properties = {
                                  cookie = {
                                    type = "object"
                                    properties = {
                                      name = {
                                        type = "string"
                                      }
                                      secure = {
                                        type = "boolean"
                                      }
                                      httpOnly = {
                                        type = "boolean"
                                      }
                                    }
                                  }
                                }
                              }
                              port = {
                                type = "integer"
                              }
                              scheme = {
                                type = "string"
                              }
                              strategy = {
                                type = "string"
                              }
                              healthCheck = {
                                type = "object"
                                properties = {
                                  path = {
                                    type = "string"
                                  }
                                  host = {
                                    type = "string"
                                  }
                                  scheme = {
                                    type = "string"
                                  }
                                  intervalSeconds = {
                                    type = "integer"
                                  }
                                  timeoutSeconds = {
                                    type = "integer"
                                  }
                                  headers = {
                                    type = "object"
                                  }
                                }
                              }
                              passHostHeader = {
                                type = "boolean"
                              }
                              responseForwarding = {
                                type = "object"
                                properties = {
                                  flushInterval = {
                                    type = "string"
                                  }
                                  weight = {
                                    type = "integer"
                                  }
                                  percent = {
                                    type = "integer"
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ]
    }
  }
}
