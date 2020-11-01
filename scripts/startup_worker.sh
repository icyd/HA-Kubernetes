#!/bin/bash

OS=Debian_Testing
VERSION=1.19

cat <<EOF > /etc/modules-load.d/kubernetes-cri.conf
br_netfilter
overlay
EOF

modprobe br_netfilter
modprobe overlay

mkdir -p /etc/apt/trusted.gpg.d
touch /etc/apt/trusted.gpg.d/libcontainers.gpg

cat <<EOF > /etc/sysctl.d/99z-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

apt update -y && apt install -y apt-transport-https curl
apt -t buster-backports install -y libseccomp2

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF

cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$VERSION/$OS/ /
EOF

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

curl -sL https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$VERSION/$OS/Release.key | sudo apt-key add --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg -
curl -sL https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key add --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg -
curl -sL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg -

apt update -y && apt install -y cri-o cri-o-runc kubelet=$VERSION.0-00 kubeadm=$VERSION.0-00

systemctl daemon-reload
systemctl enable --now crio kubelet
