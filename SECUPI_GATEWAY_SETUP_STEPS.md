# Secupi Gateway k3d Setup - Complete Step-by-Step Guide

## Prerequisites
- k3d installed locally
- Helm 3 installed
- GitLab registry credentials from Secupi team
- PostgreSQL database (local Docker or within k3d cluster)

## Setup Steps

### 1. Verify k3d Cluster and Create Namespace
```bash
kubectl cluster-info
kubectl create namespace secupi
```

### 2. Download and Extract Secupi Gateway Helm Chart
```bash
wget https://storage.googleapis.com/secupi-shared/secupi-gateway-postgresql-7.0.0-59.tgz
mkdir -p secupi-chart
tar -xzvf secupi-gateway-postgresql-7.0.0-59.tgz -C secupi-chart
ls -la secupi-chart
```

### 3. Create Kubernetes Secret for GitLab Registry
```bash
kubectl create secret docker-registry gitlab-registry-secret \
  --namespace secupi \
  --docker-server=registry.gitlab.com \
  --docker-username=<YOUR_GITLAB_USERNAME> \
  --docker-password=<YOUR_GITLAB_PASSWORD> \
  --docker-email=<YOUR_EMAIL>
```

### 4. Set Up PostgreSQL Database
Option A - Use existing PostgreSQL:
- Ensure it's accessible from your k3d cluster
- Note the connection details (host, port, database name, username, password)

Option B - Deploy PostgreSQL in k3d cluster:
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install postgresql bitnami/postgresql --namespace secupi
```

### 5. Create Required Database Schema
Connect to your PostgreSQL instance and create the customers table:
```sql
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert some test data
INSERT INTO customers (email, name) VALUES 
('user1@example.com', 'John Doe'),
('user2@example.com', 'Jane Smith'),
('user3@example.com', 'Bob Johnson');
```

### 6. Generate SSL Certificate
```bash
# Create a self-signed certificate
openssl req -x509 -newkey rsa:4096 -keyout secupi-gateway-key.pem -out secupi-gateway-cert.pem -days 365 -nodes -subj "/CN=secupi-gateway.secupi.svc.cluster.local"

# Create Kubernetes secret for SSL certificate
kubectl create secret tls secupi-gateway-tls \
  --namespace secupi \
  --cert=secupi-gateway-cert.pem \
  --key=secupi-gateway-key.pem
```

### 7. Create Custom Helm Values File
Create a file called `values-custom.yaml` with your configuration:
```yaml
# Gateway image configuration
image:
  repository: registry.gitlab.com/secupi/secupi-gateway
  tag: 7.0.0.59
  pullPolicy: IfNotPresent

# Image pull secrets
imagePullSecrets:
  - name: gitlab-registry-secret

# Environment variables
env:
  SECUPI_BOOT_URL: "https://damkil.azure.secupi.com/api/boot/download/1e81d3dee43740fbbcbd669a2c3ca3a7/secupi-boot-ea9abf50-9ebf-4e28-9a54-f56d75dec2e5.jar"
  GATEWAY_SERVER_HOST: "<YOUR_POSTGRES_HOST>"
  GATEWAY_SERVER_PORT: "<YOUR_POSTGRES_PORT>"
  GATEWAY_SERVER_DATABASE: "<YOUR_POSTGRES_DATABASE>"
  GATEWAY_SERVER_USERNAME: "<YOUR_POSTGRES_USERNAME>"
  GATEWAY_SERVER_PASSWORD: "<YOUR_POSTGRES_PASSWORD>"
  GATEWAY_SERVER_SSL_MODE: "verify-full"

# Service configuration
service:
  type: ClusterIP
  port: 5432

# SSL certificate configuration
ssl:
  enabled: true
  secretName: secupi-gateway-tls
```

### 8. Deploy Secupi Gateway Using Helm
```bash
helm install secupi-gateway ./secupi-gateway-postgresql-7.0.0-59.tgz \
  --namespace secupi \
  -f values-custom.yaml
```

### 9. Configure Network Policies (Optional but Recommended)
Create a file called `network-policy.yaml`:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: secupi-gateway-policy
  namespace: secupi
spec:
  podSelector:
    matchLabels:
      app: secupi-gateway
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: secupi
    ports:
    - protocol: TCP
      port: 5432
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: secupi
    ports:
    - protocol: TCP
      port: 5432
```

Apply the network policy:
```bash
kubectl apply -f network-policy.yaml
```

### 10. Test Database Connection
```bash
# Check if the gateway pod is running
kubectl get pods -n secupi

# Forward the gateway port locally for testing
kubectl port-forward svc/secupi-gateway 5432:5432 -n secupi

# Connect using a PostgreSQL client like psql or DBeaver
# Connection details should point to localhost:5432
```

### 11. Verify Email Masking Functionality
Using DBeaver or another PostgreSQL client:
```sql
-- Connect through the gateway and query the customers table
SELECT * FROM customers;

-- You should see masked email addresses instead of the original ones
-- Original: 'user1@example.com' should appear as something like '***@example.com'
```

## Troubleshooting Tips

1. **Check pod logs**: `kubectl logs -n secupi <secupi-gateway-pod-name>`
2. **Verify secrets**: `kubectl get secrets -n secupi`
3. **Check service status**: `kubectl get svc -n secupi`
4. **Validate network policies**: `kubectl get networkpolicies -n secupi`

## Additional Configuration

- Monitor gateway performance with built-in Kubernetes monitoring
- Implement backup procedures for gateway configuration
- Set up horizontal pod autoscaling for production use
