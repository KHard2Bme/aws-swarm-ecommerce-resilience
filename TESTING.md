✅ Project Testing Checklist

Project: E-Commerce Checkout Outage (Docker Swarm + AWS + Prometheus + Grafana)

🔹 Phase 0: Pre-Test Validation (Environment Ready)
Infrastructure

 EC2 instances running (1 manager, ≥2 workers)

 Docker installed and running on all nodes

 Docker Swarm initialized

 Workers joined successfully

 Security groups allow:

 80 (frontend)

 3000 (Grafana)

 9090 (Prometheus)

Monitoring

 Prometheus service running

 Grafana service running

 Node Exporter running on all nodes

 cAdvisor running on all nodes

 Prometheus targets UP

🔹 Phase 1: Baseline (Healthy System)
Application Validation

 Home page loads

 Product list visible

 Add to cart works

 Checkout succeeds

 Order confirmation shown

Metrics Validation (Grafana)

 CPU usage stable

 Memory usage stable

 Checkout request latency < threshold

 HTTP 2xx success rate high

 Redis healthy

Prometheus Checks

 up == 1 for all services

 http_requests_total increasing normally

🔹 Phase 2: Load Simulation (Trigger Realistic Stress)
Generate Traffic

 Open multiple browser tabs

 Repeatedly click checkout

 (Optional) Run load test:

hey -n 1000 -c 20 http://<frontend>/checkout

Validate Behavior

 Increased request rate visible

 Latency increases slightly

 System still functional

🔹 Phase 3: Outage Injection (Backend Saturation)
Trigger Failure
docker service update \
  --limit-cpu 0.1 \
  ecommerce_checkout

Verify Failure Conditions

 Checkout page loads slowly

 Checkout fails or times out

 Error message shown to user

 Cart remains intact

🔹 Phase 4: Detection (Observability in Action)
Grafana Dashboards

 Checkout CPU usage spikes

 P95 latency increases

 HTTP 5xx error rate increases

 Redis remains healthy

 Other services unaffected

Prometheus Queries

 container_cpu_usage_seconds_total

 http_request_duration_seconds_bucket

 http_requests_total{status="500"}

🔹 Phase 5: Customer Impact Validation

 Users can browse products

 Checkout intermittently fails

 No full site outage

 Revenue-impacting failure confirmed

🔹 Phase 6: Root Cause Analysis

 Identify checkout service saturation

 Confirm CPU limit misconfiguration

 Rule out:

 Network issues

 Redis failure

 Node failure

🔹 Phase 7: Recovery & Mitigation
Apply Fix
docker service update \
  --limit-cpu 1 \
  --replicas 3 \
  ecommerce_checkout

Validate Recovery

 Checkout latency drops

 Error rate decreases

 Checkout succeeds again

 Grafana metrics stabilize

🔹 Phase 8: Post-Recovery Validation

 All services healthy

 No lingering errors

 Metrics back to baseline

 Prometheus targets UP

🔹 Phase 9: Prevention Testing
Add Alerts (Optional)

 High latency alert configured

 High error rate alert configured

 CPU saturation alert configured

Resilience Improvements

 Increase default replicas

 Tune CPU limits

 Add autoscaling strategy

 Document SLOs

🔹 Phase 10: Documentation (Carrier-Grade)
Incident Artifacts

 Incident timeline

 Root cause summary

 Metrics screenshots

 Resolution steps

 Preventative actions

🧠 Final Verification (Pass/Fail)
Test Area	Result
Customer impact observed	✅
Metrics detected failure	✅
Root cause identified	    ✅
Service recovered	        ✅
Lessons documented	        ✅