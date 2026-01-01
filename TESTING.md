# Project Testing Checklist

This checklist validates the full AWS Docker Swarm + Observability project.

---

## Infrastructure Validation (Terraform)
- [ ] terraform init completes successfully
- [ ] terraform plan shows expected resources
- [ ] terraform apply provisions all resources without error
- [ ] EC2 Manager instance created
- [ ] EC2 Worker instances created
- [ ] ALB created and reachable
- [ ] Security Groups applied correctly
- [ ] Subnets span multiple AZs

---

## Docker Swarm Validation
- [ ] Docker installed on all nodes
- [ ] Swarm initialized on manager
- [ ] Workers successfully joined swarm
- [ ] docker node ls shows manager + workers
- [ ] Overlay network created

---

## Service Deployment
- [ ] frontend service running on workers
- [ ] checkout service running on workers
- [ ] prometheus running on manager
- [ ] grafana running on manager
- [ ] traffic-generator running

---

## Networking & Load Balancer
- [ ] ALB target group healthy
- [ ] ALB routes traffic to workers
- [ ] Worker nodes listening on published ports
- [ ] No services bound to manager port 80

---

## Observability
- [ ] Prometheus UI reachable
- [ ] Grafana UI reachable
- [ ] Prometheus targets are UP
- [ ] Dashboards display metrics
- [ ] ALB / node metrics visible

---

## Outage Simulation
### CPU Stress
- [ ] CPU load successfully injected
- [ ] Latency increase observed
- [ ] Grafana reflects CPU spike

### Traffic Surge
- [ ] Traffic generator increases load
- [ ] Request latency increases
- [ ] ALB health checks react

### Saturation
- [ ] Resource limits reached
- [ ] Service degradation observed
- [ ] Monitoring alerts triggered

---

## Recovery & Improvements
- [ ] Services auto-recover
- [ ] Swarm reschedules tasks
- [ ] Metrics return to baseline
- [ ] Improvements documented

---

## Cleanup
- [ ] terraform destroy completes successfully
- [ ] No AWS resources left running
- [ ] No orphaned security groups or ALBs
