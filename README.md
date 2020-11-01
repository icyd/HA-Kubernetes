# Kubernetes bootstrap cluster

Notebook to deploy HA Kubernetes cluster in GCP.

The masters and workers are private only, and only reachable through a *bastion* server. To allow public
access to the cluster an additional LoadBalancer/Ingress should be used.

Put your ssh public key in the root folder of the repo as file with name `ssh_key.pub` or simply modify its name in the file `vars.tf`.

In your GCP project create a service account and retrieve the credentials in a file name `credentials.json` in the root folder of the project or change its name in the file `provider.tf`.

This installation uses Kubernetes 1.19.0, which requires you to have in your system installed *kubectl* with the same version.

```bash
    terraform init
    terraform plan
    terraform apply

    BASTION=$(gcloud compute instances describe bastion --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    rsync -e 'ssh -o ProxyCommand="ssh -W %h:%p admin@'$BASTION'"' --rsync-path="sudo rsync" config/config.yaml admin@master-0:~/config.yaml
    ssh -o ProxyCommand="ssh -W %h:%p admin@$BASTION" admin@master-0
    sudo kubeadm init --config config.yaml --upload-certs
    exit
```

Copy the `kubeadm join` commands.

Before provisioning other master nodes with `kubeadm` remove them from the instance group and after
kubeadm finishes read them to the group. If not the provisioning fails because of connection timeout.

Run `kubeadm join` commands:

```bash
    ssh -o ProxyCommand="ssh -W %h:%p admin@$BASTION" admin@master-1
    sudo kubeadm join ...
    exit
    ssh -o ProxyCommand="ssh -W %h:%p admin@$BASTION" admin@worker-0
    sudo kubeadm join ...
    exit
    .
    .
    .
```

## Retrieve kubeconfig file

Run all the kubectl commands as `kubectl --kubeconfig=kubeconfig`.

```bash
    rsync -e 'ssh -o ProxyCommand="ssh -W %h:%p admin@'$BASTION'"' --rsync-path="sudo rsync" admin@master-0:/etc/kubernetes/admin.conf kubeconfig
    perl -i -pe 's/^(\s+server:).*/\1 https:\/\/127.0.0.1:12345/' kubeconfig
    ssh -fNT -L 12345:10.0.0.6:6443 admin@$BASTION
```

## CNI Addon

Install one of the following CNI Addons.

### WeaveNet

```bash
    kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```

### Flannel

```bash
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

### Calico

```bash
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## Smoke test

Run:

```bash
    bash ./scripts/smoke_test.sh
```

## Cleanup

```bash
    terraform destroy -auto-approve
```
