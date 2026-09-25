---
type: reference
---
## Containers
Container bits.

### Install Docker - Ubuntu 25.04

Below steps are based on <https://linuxiac.com/how-to-install-docker-on-ubuntu-24-04-lts/> : 

```bash
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

This installs the following Docker components: 
- **docker-ce**: The Docker engine itself.
- **docker-ce-cli**: A command line tool that lets you talk to the Docker daemon.
- **containerd.io**: A container runtime that manages the container’s lifecycle.
- **docker-buildx-plugin**: This extension for Docker enhances the capabilities of building images, mainly focusing on multi-platform builds.
- **docker-compose-plugin**: A configuration management plugin that helps manage multi-container Docker applications using a single YAML file.

```bash
sudo systemctl is-active docker
sudo docker run hello-world
sudo usermod -aG docker ${USER} # To allow running without 'sudo'
```

If for whatever reason you need to uninstall: 

```bash
sudo apt purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd
```

### Install Docker - RedHat/AlmaLinux

```bash
sudo dnf update -y
sudo dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
```

Logout and log back in for group changes to take effect.

Above does not install `docker-compose-plugin`.

### Public Docker Registry Logon
To login using your own Docker Hub username (cannot use email from CLI) simply do: `docker login`


### Command Commands
```bash
docker search jenkins                                     # Sample search
docker run -it centos                                     # Run image with interactive terminal shell
docker stop ID                                            # Stop running container
docker ps [-a]                                            # Lists running containers [non running ones]
docker rm ID                                              # Delete container
docker image ls                                           # List all images
docker rmi ID                                             # Delete image
docker logs -f ID                                         # Show standard output, tail option
docker tag centos centos:7.1.1503                         # Add a tag to existing image
docker cp foo.txt mycontainer:/foo.txt                    # Copy file to container
docker run -it -v ./scimsession:/scimsession centos bash  # Mount local file on container
docker container prune                                    # Remove all old containers
docker system prune                                       # Remove all old settings
docker container exec -it CONTA_NAME /bin/bash            # Attach to running container
docker top hungry_brahmagupta                             # Show container process list
docker exec -it c44b36e02322 /bin/bash                    # Open bash on/connect to running container

# Instantiate image, put in background, and expose ports to local random ports
docker run -d -P training/webapp python app.py

# Instantiate image, put in backgrnd, and expose port 5000 to 80 local
docker run -d -p 80:5000 training/webapp python app.py

# Run redis locally
docker run -d -p 6379:6379 redis

# Instantiate simple python HTTP server, expose port 8000 on 80 local
# Browsing http://192.168.99.100/ will show centos container file system
docker run -it -p 80:8000 centos:7.1.1503 python -m SimpleHTTPServer

# Instantiate image, and join to specific network
docker run -d --net=my-bridge-network --name db training/postgres

# Instantiate image, and attach to volume, with read-only option
docker run -d -P --name webapp[:ro] -v /webapp training/webapp python app.py

# Instantiate image, and attach to specific host volume, with read-only option
docker run -d -P --name /src/webapp:/opt/webapp[:ro] -v /webapp training/webapp python app.py

# Create a volume named dbdata
docker create -v /dbdata --name dbdata training/postgres /bin/true

# Instantiate image, and attach all volumes from dbdata Data Volume Container
docker run -d --volumes-from dbdata --name db1 training/postgres
```

### Docker Networking
To create an external network with a specific IP CIDR range:

```bash
docker network create --gateway 10.10.4.1 --subnet 10.10.4.0/24 NETNAME
```

### Docker Volumes
Docker volumes are usually kept under `/var/lib/docker/volumes/` and by default only accessible by `root`.

### Docker for Mac
HyperKit VM Shell

```bash
screen ~/Library/Containers/com.docker.docker/Data/vms/0/tty
linuxkit-025000000001:~# 
```

### Kubernetes
**Kubernetes** is a production-grade, open-source platform that orchestrates the placement (scheduling) and execution of application *containers* within and across computer clusters. Key elements:

- **Deployment**: A Deployment is responsible for creating and updating instances of your application

- **Node**: A node is a worker machine in Kubernetes and may be a VM or physical machine, depending on the cluster. Multiple Pods can run on one Node.
  Pod

- **Pod**: A Pod is a group of one or more application containers, such as Docker or rkt. It includes shared storage (volumes), an IP address, and information about how to run them.

- **Service**: A Kubernetes Service is an abstraction layer that defines a logical set of Pods. It enables external traffic exposure, load balancing, and service discovery for those Pods.

- **Helm Chart**: A Helm chart encapsulates a group of YAML definitions composing a specific application/package. It provides a mechanism for configuration at deploy-time and allows you to define metadata and documentation that might be useful when sharing the package. Helm can be useful in different scenarios:
  - Find and use popular software packaged as Kubernetes charts
  - Share your own applications as Kubernetes charts
  - Create reproducible builds of your Kubernetes applications
  - Intelligently manage your Kubernetes object definitions
  - Manage releases of Helm packages

- **Criticism**: There are many who argue that for many shops Kubernetes is unncessarily complex and probably should be avoided. In many cases it is easier to run Docker alone, maybe using Compose or Swarm.

### Docker Swarm
Docker Swarm is native clustering for Docker. It turns a pool of Docker hosts into a single, virtual host. Swarm serves the standard Docker API. Any tool that already talks to a Docker daemon can use Swarm to scale to multiple hosts. Examples include Dokku, Compose, Krane, Deis, DockerUI, Shipyard, Drone, Jenkins, and the Docker client itself.

### kubeadm
Creating a single control-plane cluster with kubeadm.

See <https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/>

**kubeadm** helps you bootstrap a minimum viable Kubernetes cluster that conforms to best practices. With kubeadm, your cluster should pass Kubernetes Conformance tests. Kubeadm also supports other cluster lifecycle functions, such as upgrades, downgrade, and managing bootstrap tokens.

Because you can install kubeadm on various types of machine (e.g. laptop, server, Raspberry Pi, etc.), it’s well suited for integration with provisioning systems such as Terraform or Ansible.

### kubectl Common Commands
`kubectl` is Kubernetes's Swiss Army knife. Command commands are:

```bash
kns kube-system
kubectl get all 
kubectl describe pod calico-kube-controllers-5d94b577bb-jp5hz
kubectl logs calico-kube-controllers-5ff94b558-vhjtm --namespace kube-system

BASICS
kubectl config set-context kube-system                         # Set namespace to kube-system 
kns kube-system                                                # Set namespace to kube-system with kns 
kubectl describe pod calico-kube-controllers-5ff94b558-vhjtm   # Describe pod
kubectl logs calico-kube-controllers-5ff94b558-vhjtm           # Show logs
kubectl -n kube-system logs calico-node-t9mfs                  # Show logs on specific namespace pod
kubectl apply -f CONFIG.yaml                                   # Deploy a resource
kubectl delete -f CONFIG.yaml                                  # Delete that resource
kubectl delete rs coredns-6955765f44                           # Delete specific resource: Replica Set
kubectl delete pods,services -l name=myLabel                   # Delete pods, services with specific label

BACKUP
kubectl get globalconfig --all-namespaces --export -o yaml > global-configs.yaml
kubectl get ippool --all-namespaces --export -o yaml > ip-pools.yaml
kubectl get systemnetworkpolicy.alpha --all-namespaces --export -o yaml > system-network-policies.yaml
```

### Docker Compose

Docker Compose allows one to define and run multi-container applications with Docker. You define a multi-container application in a single file, usually called `docker-compose.yaml`. One command, usually `docker-compose up`, then gets everything running. Check the version: `docker-compose --version`.

Two very rough examples of using **docker compose**: 

1. **Testing a Go Binary**:
  - This example builds an multi-state image with the `azm` utility as a sole binary:
  - The `Dockerfile`:

     ```bash
     # # On Debian GNU/Linux 12 (bookworm) - image size ~= 928MB
     # FROM golang:latest
     # or
     # On Alpine Linux v3.18  - image size ~= 335MB
     FROM golang:alpine
     #
     WORKDIR /app
     COPY . .
     # Note that GOPATH=/go
     RUN go build -ldflags "-s -w" -o /go/bin/azm
     CMD ["azm"]

     # EXPLORE multistage builds - image size ~= really small is the promise!
     # # STEP 1: Build your binary
     # FROM golang:alpine AS builder
     # RUN apk update
     # RUN apk add --no-cache git ca-certificates tzdata && update-ca-certificates
     # COPY . .
     # #RUN go get -d -v ./...
     # #RUN go build -o /bin/my-service
     # RUN go build -ldflags "-s -w" -o /bin/azm
     # 
     # # STEP 2: Use Scratch to build your smallest image
     # FROM scratch
     # COPY --from=builder /etc/ssl/certs/* /etc/ssl/certs/
     # COPY --from=builder /bin/ /bin/
     # CMD ["/bin/azm"]
     ```

  - The `docker-compose.yaml` files:

     ```bash
     version: '3'
     services:
       azm:
         build:
           context: .  # Path to your GoLang application code
           dockerfile: Dockerfile
         image: azm
         command: sh -c '
           echo "===========" &&
           cat /etc/os-release &&
           echo "===========" &&
           azm -id &&
           echo "===========" &&
           azm -s'
         container_name: azm
         volumes:
           - ./:/app
         environment:
           - MAZ_CLIENT_ID=${MAZ_CLIENT_ID}
           - MAZ_CLIENT_SECRET=${MAZ_CLIENT_SECRET}
           - MAZ_TENANT_ID=${MAZ_TENANT_ID}
         working_dir: /app

     # BUILD & RUN: docker compose up --build
     # JUST RUN   : docker compose up
     # INSPECT    : docker compose run --build azm bash
     ```

2. **Testing a Python script that gets Azure tokens**:
  - Working Docker and Docker Compose environment. Note that below examples are using version 2 of Docker Compose.
  - References:
    - Installing Docker: <https://docs.docker.com/engine/install/rhel/>
    - Docker Compose: <https://docs.docker.com/reference/compose-file/legacy-versions/>
  - Docker Socket Issues:
    - If you encounter any `permissions denied` issues with the docker daemon, try these commands:
       ```bash
       sudo usermod -aG docker your_username     # Ubuntu
       sudo usermod -aG podman your_username     # RHEL
       sudo systemctl restart docker
       docker run hello-world                    # To confirm it is fixed

       # Alternatively, try 
        
       sudo chown your_username:docker /var/run/docker.sock
       sudo chmod 660 /var/run/docker.sock
       ```
  - Make sure you define/export the 3 required environment variables: 

     ```bash
     export MAZ_TENANT_ID="tenant-id-uuid-string"
     export MAZ_CLIENT_ID="your-client-ID-uuid-string"
     export MAZ_CLIENT_SECRET="client-secret-string"
     ```

  - Get the two files from the gkit scripts folder and keep them in one directory, for example a clone of that repo:
    - [aztoken_compose.yaml](https://github.com/queone/gkit/blob/main/scripts/aztoken_compose.yaml): the compose file
    - [aztoken.py](https://github.com/queone/gkit/blob/main/scripts/aztoken.py): the script, which gets a fresh token every 5 seconds and prints its details
  - Then you can build and run for the first time, or run subsequent times.
      - `docker compose -f aztoken_compose.yaml up --build`: To build and run for the first time.
      - `docker compose -f aztoken_compose.yaml up`: To run subsequent times.
    - Edit your copy of `aztoken.py` to play with different behavior, like using a different scope and so on.

### Docker Images

To build a very small, almost empty container Docker image, build using `FROM scratch`, for example: 

```bash
$ vi hello.sh
#!/bin/bash
echo Hello
$ chmod 755 hello.sh
$ vi Dockerfile
FROM scratch
ADD hello.sh /
CMD ["/hello.sh"]
$ docker build .
```

### Docker Multi-Stage Builds for Standalone Go Binaries

Docker multi-stage builds offer several key advantages for **standalone Go binaries**, combining build-time flexibility with minimal final images:

**Core Benefits**:
1. **Tiny Production Images** (~10-20MB)
   - Final image contains *only* the binary (no compiler, SDK, or build tools)
   - Example: `FROM scratch` images for truly minimal deployments

2. **Build-Time Isolation**
   - Complex build dependencies (like CGO, code generators) stay in build stage
   - No risk of build tools ending up in production

3. **Security Hardening**
   - No unnecessary packages = smaller attack surface
   - Can use `distroless` or `scratch` as final base

4. **Single Dockerfile Workflow**
   ```bash
   # Stage 1: Build
   FROM golang:1.21 as builder
   WORKDIR /app
   COPY . .
   RUN CGO_ENABLED=0 go build -o /bin/app ./cmd/main.go

   # Stage 2: Runtime  
   FROM scratch
   COPY --from=builder /bin/app /app
   ENTRYPOINT ["/app"]
   ```
5. **Build Cache Optimization**
   - Dependency downloads cached separately from code changes
   - Faster rebuilds when only source files change

**Go-Specific Advantages**:
   - **Static Binaries Work Perfectly**  
     `CGO_ENABLED=0` builds run natively in `scratch` images
   - **No Runtime Dependencies**  
     Go binaries include everything needed (unlike Python/Java)
   - **Cross-Compilation Support**  
     Build for Linux AMD64 from macOS/Windows in CI

**Real-World Impact**:
   | Metric       | Single-Stage | Multi-Stage |
   |--------------|--------------|-------------|
   | Image Size   | ~800MB       | ~10MB       |
   | CVEs         | 100+         | 0           |
   | Build Time   | 2min         | 1min (cached)|

**When Not To Use**:
   - If you need shell access for debugging in production, swap `scratch` for `alpine` (still only ~5MB).
