import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";
import * as fs from "fs";
import * as path from "path";
import * as os from "os";

// Config
const config = new pulumi.Config();
const gcpConfig = new pulumi.Config("gcp");
const project = gcpConfig.require("project");
const region = gcpConfig.get("region") || "us-central1";
const zone = gcpConfig.get("zone") || "us-central1-a";
const machineType = config.get("machineType") || "e2-micro"; // e2-micro is eligible for GCP Always Free

// Read SSH public key (fallback to default if not present)
const sshKeyPath = path.join(os.homedir(), ".ssh", "id_ed25519.pub");
let sshPublicKey = "";
if (fs.existsSync(sshKeyPath)) {
  sshPublicKey = fs.readFileSync(sshKeyPath, "utf-8").trim();
} else {
  sshPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFBEWDfkMwVm/ZzP7IP8Kzw8ufOyavqUR/o/T6wckHvW kamal@modern-rails";
}

// 1. Static External IP Address (for Kamal zero-downtime routing & DNS)
const staticIp = new gcp.compute.Address("modern-rails-static-ip", {
  name: "modern-rails-static-ip",
  project: project,
  region: region,
  description: "Static IP for Rails 8 Web Server deployed via Kamal",
});

// 2. Firewall Rules for Web (80, 443) and SSH (22)
const webFirewall = new gcp.compute.Firewall("modern-rails-allow-web", {
  name: "modern-rails-allow-web",
  project: project,
  network: "default",
  allows: [
    { protocol: "tcp", ports: ["80", "443"] },
  ],
  sourceRanges: ["0.0.0.0/0"],
  targetTags: ["modern-rails-server"],
  description: "Allow HTTP and HTTPS inbound traffic for Rails application",
});

const sshFirewall = new gcp.compute.Firewall("modern-rails-allow-ssh", {
  name: "modern-rails-allow-ssh",
  project: project,
  network: "default",
  allows: [
    { protocol: "tcp", ports: ["22"] },
  ],
  sourceRanges: ["0.0.0.0/0"],
  targetTags: ["modern-rails-server"],
  description: "Allow SSH access for Kamal deployment",
});

// 3. Artifact Registry (Private Docker Registry for Kamal deployments)
const artifactRepo = new gcp.artifactregistry.Repository("modern-rails-docker-repo", {
  repositoryId: "modern-rails-repo",
  format: "DOCKER",
  location: region,
  project: project,
  description: "Docker repository for modern-rails application images",
});

// 4. Service Account & IAM for CI/CD & Kamal deployment to Artifact Registry
const deployerSa = new gcp.serviceaccount.Account("kamal-deployer-sa", {
  accountId: "kamal-deployer",
  displayName: "Kamal Deployer Service Account",
  project: project,
});

const artifactWriterBinding = new gcp.projects.IAMMember("deployer-artifact-writer", {
  project: project,
  role: "roles/artifactregistry.writer",
  member: pulumi.interpolate`serviceAccount:${deployerSa.email}`,
});

const artifactReaderBinding = new gcp.projects.IAMMember("deployer-artifact-reader", {
  project: project,
  role: "roles/artifactregistry.reader",
  member: pulumi.interpolate`serviceAccount:${deployerSa.email}`,
});

const deployerKey = new gcp.serviceaccount.Key("kamal-deployer-key", {
  serviceAccountId: deployerSa.name,
  publicKeyType: "TYPE_X509_PEM_FILE",
}, { dependsOn: [artifactWriterBinding, artifactReaderBinding] });

// 5. Compute Engine VM Instance (Ubuntu 24.04 with Docker auto-install & 2GB Swap)
const startupScript = `#!/bin/bash
set -e
echo "Starting initialization script for Kamal host..."

# Setup 2GB swap file to prevent OOM on e2-micro
if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo "/swapfile none swap sw 0 0" >> /etc/fstab
fi

apt-get update -qq
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    docker.io

systemctl enable --now docker

# Create deploy user with passwordless sudo & docker permissions
useradd -m -s /bin/bash deploy || true
usermod -aG docker deploy || true
usermod -aG sudo deploy || true
echo "deploy ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-deploy-user
chmod 0440 /etc/sudoers.d/90-deploy-user

# Setup SSH directory for deploy user
mkdir -p /home/deploy/.ssh
echo "${sshPublicKey}" >> /home/deploy/.ssh/authorized_keys
chmod 700 /home/deploy/.ssh
chmod 600 /home/deploy/.ssh/authorized_keys
chown -R deploy:deploy /home/deploy/.ssh

echo "Initialization complete!"
`;

const instance = new gcp.compute.Instance("modern-rails-server", {
  name: "modern-rails-server",
  project: project,
  zone: zone,
  machineType: machineType,
  tags: ["modern-rails-server", "http-server", "https-server"],

  bootDisk: {
    initializeParams: {
      image: "ubuntu-os-cloud/ubuntu-2404-lts-amd64",
      size: 30, // 30GB standard persistent disk (GCP Always Free)
      type: "pd-standard",
    },
  },

  networkInterfaces: [{
    network: "default",
    accessConfigs: [{
      natIp: staticIp.address,
    }],
  }],

  metadata: {
    "ssh-keys": `deploy:${sshPublicKey}`,
    "startup-script": startupScript,
  },

  serviceAccount: {
    scopes: ["https://www.googleapis.com/auth/cloud-platform"],
  },

  allowStoppingForUpdate: true,
}, { dependsOn: [staticIp, webFirewall, sshFirewall] });

// Outputs
export const serverIp = staticIp.address;
export const serverName = instance.name;
export const registryUrl = pulumi.interpolate`${region}-docker.pkg.dev/${project}/${artifactRepo.repositoryId}/app`;
export const gcpServiceAccountKeyBase64 = deployerKey.privateKey;
export const sshCommand = pulumi.interpolate`ssh -i ~/.ssh/id_ed25519 deploy@${staticIp.address}`;
export const kamalDeployServer = staticIp.address;
