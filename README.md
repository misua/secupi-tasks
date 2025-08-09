# Secupi Gateway SSL Deployment on k3d Kubernetes

## Overview
This repository contains all the necessary configurations and documentation for deploying Secupi Gateway on a local k3d Kubernetes cluster with SSL verify-full mode enabled for secure PostgreSQL database connectivity and email masking functionality.

link to the complete guide: [SECUPI_COMPLETE_DEPLOYMENT_GUIDE.md](SECUPI_COMPLETE_DEPLOYMENT_GUIDE.md)

## Important Notes

### k3d Cluster Persistence

**Important**: k3d clusters are ephemeral by default. When you stop or delete a k3d cluster, all workloads, data, and configurations are lost. This is why you're unable to log in to your cluster after stopping it.

To prevent this issue in the future:

1. **For development/testing**: Always recreate the cluster using the same creation commands from the guide
2. **For persistent data**: Use external PostgreSQL or configure persistent volumes
3. **For production**: Consider using a managed Kubernetes service instead of k3d

The complete deployment guide includes detailed steps for recreating the cluster and all components after stopping.