---
sidebar_position: 4
title: Security Checklists
---

# Security Checklists

Copy these and check them off.

---

## Initial Setup (do once)

- [ ] Run `12-security-setup.sh`
- [ ] SSH root login disabled
- [ ] Fail2Ban active
- [ ] CrowdSec installed and enrolled
- [ ] Automatic security updates enabled
- [ ] Firewall configured (UFW)
- [ ] Cloudflare tunnel active (no open ports)
- [ ] Cloudflare Access on all admin services
- [ ] Strong passwords on every service
- [ ] SSH key auth (disable password auth)

## Weekly

- [ ] Run `sec` (security check)
- [ ] Run `health` (service check)
- [ ] Check fail2ban: `sudo fail2ban-client status sshd`
- [ ] Check pending updates: `apt list --upgradable`
- [ ] Glance at Cloudflare analytics for unusual traffic

## Monthly

- [ ] Run `sudo lynis audit system`
- [ ] Run `sudo rkhunter --check`
- [ ] Run `sudo aide --check`
- [ ] Scan Docker images: `trivy image IMAGE`
- [ ] Review audit logs: `sudo aureport`
- [ ] Test backups (can you actually restore?)
- [ ] Update all Docker images
- [ ] Review Cloudflare Access policies

## After Any Incident

- [ ] Change all passwords
- [ ] Rotate SSH keys
- [ ] Rotate Cloudflare tunnel token
- [ ] Full security scan (lynis + rkhunter + aide)
- [ ] Review how the breach happened
- [ ] Document and fix the vulnerability
