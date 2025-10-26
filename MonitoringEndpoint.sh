#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 <urls_file>"
    exit 1
fi

URLS_FILE="$1"

# Create comprehensive monitoring paths with trailing slashes
cat > comprehensive_monitoring_paths.txt << 'EOF'
# Spring Boot Actuator
/actuator/
/actuator/health/
/actuator/metrics/
/actuator/prometheus/
/actuator/env/
/actuator/info/
/actuator/beans/
/actuator/mappings/
/actuator/threaddump/
/actuator/heapdump/
/actuator/httptrace/
/actuator/auditevents/
/actuator/loggers/
/actuator/configprops/
/actuator/conditions/
/actuator/sessions/
/actuator/shutdown/
/actuator/features/
/actuator/logfile/
/actuator/flyway/
/actuator/liquibase/
/actuator/refresh/
/actuator/restart/

# Legacy Spring Boot
/metrics/
/health/
/info/
/env/
/beans/
/autoconfig/
/dump/
/trace/
/mappings/
/configprops/
/loggers/
/auditevents/
/threaddump/
/heapdump/

# Dropwizard Metrics
/admin/
/admin/metrics/
/admin/healthcheck/
/admin/ping/
/admin/threads/
/admin/health/
/admin/healthchecks/

# Micrometer
/prometheus/
/micrometer/
/micrometer/prometheus/
/actuator/micrometer/

# JMX & Management
/jolokia/
/jolokia/read/
/jolokia/list/
/jolokia/version/
/jolokia/exec/
/hawtio/
/hawtio/jolokia/
/hawtio/auth/
/manager/
/manager/jmxproxy/
/manager/status/
/manager/html/
/webapps/

# Application Specific
/status/
/healthcheck/
/ready/
/live/
/version/
/build/
/git/
/api/health/
/api/metrics/
/api/status/
/api/version/
/api/info/
/admin/
/management/
/console/
/webconsole/
/monitoring/
/debug/
/diagnostic/
/profiling/
/internal/health/
/internal/metrics/

# Database & Cache
/db/
/db/health/
/database/
/database/health/
/redis/
/redis/health/
/cache/
/cache/health/
/mongo/
/mongo/health/
/mysql/health/
/postgres/health/
/oracle/health/
/elasticsearch/health/
/kafka/health/
/rabbitmq/health/

# Kubernetes & Cloud Native
/readyz/
/livez/
/healthz/
/statusz/
/metricsz/
/cluster/health/
/cluster/status/
/pod/health/
/node/health/

# Web Servers & Proxies
/nginx-status/
/apache-status/
/server-status/
/server-info/
/mod_status/

# Monitoring Systems
/graphite/
/grafana/
/kibana/
/elastic/
/zabbix/
/nagios/
/prometheus/targets/
/prometheus/config/
/prometheus/rules/

# Custom Business Metrics
/business/metrics/
/application/metrics/
/service/metrics/
/performance/metrics/
/system/metrics/
/infrastructure/metrics/

# Legacy & Alternative Paths
/monitor/
/monitor/health/
/monitor/metrics/
/check/
/check/health/
/ping/
/stats/
/statistics/
/diagnostics/
/diagnostics/health/
/actuator/heap/
/actuator/dump/
/actuator/trace/

# Spring Cloud
/hystrix.stream/
/hystrix/
/turbine.stream/
/configserver/
/eureka/
/zuul/
/gateway/
/gateway/actuator/

# Additional Actuator Endpoints
/actuator/caches/
/actuator/conditions/
/actuator/configprops/
/actuator/health/
/actuator/httptrace/
/actuator/info/
/actuator/integrationgraph/
/actuator/loggers/
/actuator/mappings/
/actuator/metrics/
/actuator/scheduledtasks/
/actuator/sessions/
/actuator/shutdown/
/actuator/startup/
/actuator/threaddump/

# Quarkus
/q/health/
/q/metrics/
/q/info/

# Micronaut
/health/
/metrics/
/routes/

# Vert.x
/vertx/
/vertx/metrics/

# WildFly
/management/
/console/

# Tomcat
/manager/status/
/manager/html/

# Jetty
/management/

# WebSphere
/ibm/console/

# Additional Kubernetes
/metrics/
/debug/pprof/
/debug/pprof/heap/
/debug/pprof/profile/
/debug/pprof/goroutine/
/debug/pprof/threadcreate/
/debug/pprof/block/
/debug/pprof/mutex/

# .NET Core
/healthchecks/
/metrics/
/info/

# Node.js
/metrics/
/health/
/status/
/debug/

# Python
/metrics/
/health/
/status/
/debug/

# Ruby
/metrics/
/health/
/status/
/debug/

# PHP
/status/
/health/
/metrics/

# Go
/metrics/
/health/
/debug/
/debug/pprof/
/debug/vars/

# Rust
/metrics/
/health/
/ready/
EOF

# Read paths from file into array
readarray -t paths < comprehensive_monitoring_paths.txt

# Remove comment lines and empty lines
clean_paths=()
for path in "${paths[@]}"; do
    if [[ ! "$path" =~ ^# ]] && [[ ! -z "$path" ]]; then
        clean_paths+=("$path")
    fi
done

paths=("${clean_paths[@]}")

echo "🔍 Comprehensive Monitoring Endpoints Scanner"
echo "📁 Input: $URLS_FILE"
echo "🔢 URLs: $(wc -l < "$URLS_FILE")"
echo "🛣️  Paths: ${#paths[@]} (with trailing slashes)"
echo "⏳ Starting scan..."

# Create temporary file for results
TEMP_RESULTS="temp_monitoring_$$.txt"

# Test each path with progress
for ((i=0; i<${#paths[@]}; i++)); do
    path="${paths[i]}"
    progress=$(( (i + 1) * 100 / ${#paths[@]} ))
    echo -ne "⏳ Progress: $progress% ($((i + 1))/${#paths[@]}) - Testing: $path\r"
    
    cat "$URLS_FILE" | httpx -silent -path "$path" -status-code -content-length -title -content-type -mc 200,301,302 >> "$TEMP_RESULTS"
    
    # Also test without trailing slash for the same path
    if [[ "$path" == */ ]]; then
        path_without_slash="${path%/}"
        cat "$URLS_FILE" | httpx -silent -path "$path_without_slash" -status-code -content-length -title -content-type -mc 200,301,302 >> "$TEMP_RESULTS"
    fi
done

echo -e "\n✅ Scan complete!"

# Sort and remove duplicates
sort -u "$TEMP_RESULTS" > monitoring_results.txt
rm -f "$TEMP_RESULTS"

total_found=$(wc -l < monitoring_results.txt 2>/dev/null || echo 0)
echo "📊 Total unique endpoints found: $total_found"

# Categorize results
if [ $total_found -gt 0 ]; then
    echo ""
    echo "📋 Categorized Results:"
    echo "======================"
    grep -c "actuator" monitoring_results.txt | xargs echo "🔧 Spring Boot Actuators:"
    grep -c "metrics" monitoring_results.txt | xargs echo "📈 Metrics Endpoints:"
    grep -c "health" monitoring_results.txt | xargs echo "❤️  Health Checks:"
    grep -c "prometheus" monitoring_results.txt | xargs echo "📊 Prometheus:"
    grep -c "jolokia" monitoring_results.txt | xargs echo "☕ JMX (Jolokia):"
    grep -c "readyz\|livez\|healthz" monitoring_results.txt | xargs echo "☸️  Kubernetes:"
    grep -c "admin" monitoring_results.txt | xargs echo "⚙️  Admin Endpoints:"
    grep -c "debug" monitoring_results.txt | xargs echo "🐛 Debug Endpoints:"
    echo ""
    echo "🔍 Top 20 discovered endpoints:"
    head -20 monitoring_results.txt
fi

# Cleanup
rm -f comprehensive_monitoring_paths.txt

echo ""
echo "💾 Wordlist saved to: comprehensive_monitoring_paths.txt"
echo "📄 Results saved to: monitoring_results.txt"
