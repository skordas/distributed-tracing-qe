#!/bin/bash

# - ref: operatorhub-subscribe-elasticsearch-operator
echo "------====== Subscribe ElasticSearch Operator ======------"

wget -q https://raw.githubusercontent.com/skordas/release/master/ci-operator/step-registry/operatorhub/subscribe/elasticsearch-operator/operatorhub-subscribe-elasticsearch-operator-commands.sh

export SHARED_DIR=""
export EO_SUB_PACKAGE=elasticsearch-operator
export EO_SUB_SOURCE=redhat-operators
export EO_SUB_CHANNEL=stable
export EO_SUB_INSTALL_NAMESPACE=openshift-operators-redhat
export EO_SUB_TARGET_NAMESPACES=""

bash operatorhub-subscribe-elasticsearch-operator-commands.sh

# - ref: operatorhub-subscribe-amq-streams
echo "------====== Subscribe amg streams ======------"

wget -q https://raw.githubusercontent.com/skordas/release/master/ci-operator/step-registry/operatorhub/subscribe/amq-streams/operatorhub-subscribe-amq-streams-commands.sh

export AMQ_PACKAGE=amq-streams
export AMQ_SOURCE=redhat-operators
export AMQ_CHANNEL=stable
export AMQ_NAMESPACE=openshift-operators
export AMQ_TARGET_NAMESPACES=""

bash operatorhub-subscribe-amq-streams-commands.sh

# - ref: distributed-tracing-install-jaeger-product
echo "------====== Installation of Distributed Tracing - Jaeger ======------"

wget -q https://raw.githubusercontent.com/skordas/release/master/ci-operator/step-registry/distributed-tracing/install/jaeger-product/distributed-tracing-install-jaeger-product-commands.sh

export JAEGER_PACKAGE=jaeger-product
export JAEGER_SOURCE=redhat-operators
export JAEGER_CHANNEL=stable
export JAEGER_NAMESPACE=openshift-distributed-tracing
export JAEGER_TARGET_NAMESPACES=""

bash distributed-tracing-install-jaeger-product-commands.sh

# - ref: distributed-tracing-install-tempo-product
echo "------====== Installation Distributed Tracing - Tempo Product ======------"

wget -q https://raw.githubusercontent.com/skordas/release/master/ci-operator/step-registry/distributed-tracing/install/tempo-product/distributed-tracing-install-tempo-product-commands.sh

export TEMPO_PACKAGE=tempo-product
export TEMPO_SOURCE=redhat-operators
export TEMPO_CHANNEL=stable
export TEMPO_NAMESPACE=openshift-operators
export TEMPO_TARGET_NAMESPACES=""

bash distributed-tracing-install-tempo-product-commands.sh

# - ref: distributed-tracing-install-opentelemetry-product
echo "------====== Installation Distributed Tracing - OpenTelemetry ======------"

wget -q https://raw.githubusercontent.com/skordas/release/master/ci-operator/step-registry/distributed-tracing/install/opentelemetry-product/distributed-tracing-install-opentelemetry-product-commands.sh

export OTEL_PACKAGE=opentelemetry-product
export OTEL_SOURCE=redhat-operators
export OTEL_CHANNEL=stable
export OTEL_NAMESPACE=openshift-operators
export OTEL_TARGET_NAMESPACES=""

bash distributed-tracing-install-opentelemetry-product-commands.sh

# Why to keep the mess
rm operatorhub-subscribe-elasticsearch-operator-commands.sh
rm operatorhub-subscribe-amq-streams-commands.sh
rm distributed-tracing-install-jaeger-product-commands.sh
rm distributed-tracing-install-tempo-product-commands.sh
rm distributed-tracing-install-opentelemetry-product-commands.sh

