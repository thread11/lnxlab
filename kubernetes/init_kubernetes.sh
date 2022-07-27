#!/bin/bash

# VERSION="1.18.0"
VERSION="1.23.8"

if ! (which yum >/dev/null 2>&1); then
  echo "support CentOS only"
  exit 1
fi

function f_init_system() {
  echo "-- init system"

  echo "-- disable selinux"
  if ! $(grep -q "^SELINUX=disabled" /etc/selinux/config); then
    sed -i "s/^SELINUX=.*/SELINUX=disabled/g" /etc/selinux/config
  fi
  if ! $(getenforce |grep -q "Disabled"); then
    setenforce 0
  fi

  echo "-- stop firewalld"
  if (systemctl --no-pager status firewalld >/dev/null 2>&1); then
    systemctl stop firewalld
  fi
  echo "-- disable firewalld"
  if (systemctl is-enabled firewalld >/dev/null 2>&1); then
    systemctl disable firewalld
  fi

  echo "-- turn off swap"
  if [ "$(swapon -s |wc -l)" -gt 0 ]; then
    swapoff -a
  fi

  echo "-- turn on /proc/sys/net/ipv4/ip_forward"
  if ! (grep "net.ipv4.ip_forward" /etc/sysctl.conf |grep -q -v ".*#.*net.ipv4.ip_forward"); then
    echo "net.ipv4.ip_forward = 1" >>/etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
  fi
  if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "0" ]; then
    echo "1" >/proc/sys/net/ipv4/ip_forward
  fi
}

function f_check_system() {
  echo "-- check system"

  echo "-- check selinux"
  if ! $(grep -q "^SELINUX=disabled" /etc/selinux/config); then
    echo "check failed"
  fi
  if ! $(getenforce |grep -q "Disabled"); then
    echo "check failed"
  fi

  echo "-- check firewalld"
  if (systemctl --no-pager status firewalld >/dev/null 2>&1); then
    echo "check failed"
  fi
  echo "-- check firewalld"
  if (systemctl is-enabled firewalld >/dev/null 2>&1); then
    echo "check failed"
  fi

  echo "-- check swap"
  if [ "$(swapon -s |wc -l)" -gt 0 ]; then
    echo "check failed"
  fi

  echo "-- check /proc/sys/net/ipv4/ip_forward"
  if ! (grep "net.ipv4.ip_forward" /etc/sysctl.conf |grep -q -v ".*#.*net.ipv4.ip_forward"); then
    echo "check failed"
  fi
  if [ "$(cat /proc/sys/net/ipv4/ip_forward)" = "0" ]; then
    echo "check failed"
  fi
}

function f_init_docker() {
  echo "-- init docker"

  echo "-- install docker"
  if [ ! -f /etc/yum.repos.d/docker-ce.repo ]; then
    wget "https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo" -O /etc/yum.repos.d/docker-ce.repo
  fi
  if ! (rpm -qa |grep -q "docker-ce"); then
    yum install docker-ce -y
    rpm -qa |grep "docker"
  fi

  echo "-- setup docker"
  if [ ! -f /etc/docker/daemon.json ]; then
    mkdir -p /etc/docker
cat <<EOF >/etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
  fi

  echo "-- start docker"
  if ! (systemctl --no-pager status docker >/dev/null 2>&1); then
    systemctl start docker
    systemctl --no-pager status docker
  fi

  echo "-- enable docker"
  if ! (systemctl is-enabled docker >/dev/null 2>&1); then
    systemctl enable docker
    systemctl is-enabled docker
  fi
}

function f_check_docker() {
  echo "-- check docker"

  echo "-- check docker"
  if ! (rpm -qa |grep -q "docker-ce"); then
    echo "check failed"
  fi

  echo "-- check docker"
  if [ ! -f /etc/docker/daemon.json ]; then
    echo "check failed"
  fi

  echo "-- check docker"
  if ! (grep -q "native.cgroupdriver=systemd" /etc/docker/daemon.json 2>/dev/null); then
    echo "check failed"
  fi

  echo "-- check docker"
  if ! (systemctl --no-pager status docker >/dev/null 2>&1); then
    echo "check failed"
  fi

  echo "-- check docker"
  if ! (systemctl is-enabled docker >/dev/null 2>&1); then
    echo "check failed"
  fi
}

function f_init_kubernetes() {
  echo "-- init kubernetes"

  echo "-- install kubernetes"
  if [ ! -f /etc/yum.repos.d/kubernetes.repo ]; then
cat <<EOF >/etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
enable=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
  fi
  if ! (rpm -qa |grep -q "kubelet"); then
    # yum install kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0 -y
    # yum install kubelet-1.23.8 kubeadm-1.23.8 kubectl-1.23.8 -y
    yum install kubelet-"$VERSION" kubeadm-"$VERSION" kubectl-"$VERSION" -y

    rpm -qa |grep -q "kubelet"
  fi

  echo "-- start kubernetes"
  if ! (systemctl --no-pager status kubelet >/dev/null 2>&1); then
    systemctl start kubelet
    systemctl --no-pager status kubelet
  fi

  echo "-- enable kubernetes"
  if ! (systemctl is-enabled kubelet >/dev/null 2>&1); then
    systemctl enable kubelet
    systemctl is-enabled kubelet
  fi

  echo "-- turn on /proc/sys/net/bridge/bridge-nf-call-iptables"
  if [ -f /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
    if ! (grep "net.bridge.bridge-nf-call-iptables" /etc/sysctl.conf |grep -q -v ".*#.*net.bridge.bridge-nf-call-iptables"); then
      echo "net.bridge.bridge-nf-call-iptables = 1" >>/etc/sysctl.conf
      sysctl -p /etc/sysctl.conf
    fi
    if [ "$(cat /proc/sys/net/bridge/bridge-nf-call-iptables)" = "0" ]; then
      echo "1" >/proc/sys/net/bridge/bridge-nf-call-iptables
    fi
  fi
}

function f_check_kubernetes() {
  echo "-- check kubernetes"

  echo "-- check kubernetes"
  if ! (rpm -qa |grep -q "kubelet"); then
    echo "check failed"
  fi

  echo "-- check kubernetes"
  if ! (systemctl --no-pager status kubelet >/dev/null 2>&1); then
    echo "check failed"
  fi

  echo "-- check kubernetes"
  if ! (systemctl is-enabled kubelet >/dev/null 2>&1); then
    echo "check failed"
  fi

  echo "-- check /proc/sys/net/bridge/bridge-nf-call-iptables"
  if [ ! -f /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
    echo "check failed"
  fi
  if [ -f /proc/sys/net/bridge/bridge-nf-call-iptables ]; then
    if [ "$(cat /proc/sys/net/bridge/bridge-nf-call-iptables)" = "0" ]; then
      echo "check failed"
    fi
  fi
}

function f_init_master() {
  # ip a, how to delete tunl0@NONE?
  # ip=$(ip a |grep "inet " |grep -v -E "127.0.0.1|172.17.0.1" |tr "/" " " |awk '{print $2}')
  ip=$(ifconfig |grep "inet " |grep -v -E "127.0.0.1|172.17.0.1" |tr "/" " " |awk '{print $2}')

  if [ -z "$ip" ]; then
    echo "ip not exist"
    return 1
  fi

  if ! (echo "$ip" |xargs |grep -q -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"); then
    echo "$ip"
    echo "ip not match"
    return 1
  fi

  echo "-- init master"
  if [ ! -f /etc/kubernetes/manifests/kube-apiserver.yaml ]; then
    # kubeadm init \
    #   --kubernetes-version v1.18.0 \
    #   --apiserver-advertise-address="$ip" \
    #   --service-cidr=10.96.0.0/12 \
    #   --pod-network-cidr=10.244.0.0/16 \
    #   --image-repository registry.aliyuncs.com/google_containers

    # kubeadm init \
    #   --kubernetes-version v1.23.8 \
    #   --apiserver-advertise-address="$ip" \
    #   --service-cidr=10.96.0.0/12 \
    #   --pod-network-cidr=10.244.0.0/16 \
    #   --image-repository registry.aliyuncs.com/google_containers

    set -x
    kubeadm init \
      --kubernetes-version v"$VERSION" \
      --apiserver-advertise-address="$ip" \
      --service-cidr=10.96.0.0/12 \
      --pod-network-cidr=10.244.0.0/16 \
      --image-repository registry.aliyuncs.com/google_containers
    set +x

    if [ "$?" -eq 0 ]; then
      mkdir -p $HOME/.kube
      sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
      sudo chown $(id -u):$(id -g) $HOME/.kube/config
    fi
  fi
}

function f_init_token() {
  echo "-- init token"
  kubeadm token create --print-join-command
}

function f_init_flannel() {
  echo "-- init flannel"

  if [ -f kube-flannel.yml ]; then
    return 1
  fi

  local count
  count=0
  while [ "$count" -lt 10 ]; do
    echo "$count"
    timeout 5 wget "https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml" -O kube-flannel.yml
    [ $? -eq 0 ] && break
    count=$((count+1))
  done

  if [ -f kube-flannel.yml ]; then
    \cp -af kube-flannel.yml kube-flannel.yml.bk.raw.yml
    if [ "$VERSION" = "1.18.0" ]; then
      sed -i "s/v0.18.0/v0.17.0/g" kube-flannel.yml
    fi
    diff -u kube-flannel.yml.bk.raw.yml kube-flannel.yml
    kubectl apply -f kube-flannel.yml
  fi
}

function f_delete_flannel() {
  echo "-- delete flannel"

  if [ -f kube-flannel.yml ]; then
    kubectl delete -f kube-flannel.yml
  fi

  rm -f /etc/cni/net.d/10-flannel.conflist

  ifconfig cni0 down
  ip link delete cni0
  ifconfig flannel.1 down
  ip link delete flannel.1

  systemctl restart kubelet
}

function f_init_calico() {
  echo "-- init calico"

  if [ -f tigera-operator.yaml ] || [ -f custom-resources.yaml ]; then
    return 1
  fi

  local count
  count=0
  while [ "$count" -lt 10 ]; do
    echo "$count"
    timeout 5 wget "https://projectcalico.docs.tigera.io/manifests/tigera-operator.yaml" -O tigera-operator.yaml
    [ $? -eq 0 ] && break
    count=$((count+1))
  done
  count=0
  while [ "$count" -lt 10 ]; do
    echo "$count"
    timeout 5 wget "https://projectcalico.docs.tigera.io/manifests/custom-resources.yaml" -O custom-resources.yaml
    [ $? -eq 0 ] && break
    count=$((count+1))
  done

  if [ -f tigera-operator.yaml ]; then
    \cp -af tigera-operator.yaml tigera-operator.yaml.bk.raw.yaml
    diff -u tigera-operator.yaml.bk.raw.yaml tigera-operator.yaml
    kubectl apply -f tigera-operator.yaml
  fi

  if [ -f custom-resources.yaml ]; then
    \cp -af custom-resources.yaml custom-resources.yaml.bk.raw.yaml
    sed -i "s%cidr: 192.168.0.0/16%cidr: 10.244.0.0/16%g" custom-resources.yaml
    sed -i "s%encapsulation: VXLANCrossSubnet%encapsulation: IPIP%g" custom-resources.yaml
    diff -u custom-resources.yaml.bk.raw.yaml custom-resources.yaml
    kubectl apply -f custom-resources.yaml
  fi
}

function f_delete_calico() {
  echo "-- delete calico"

  if [ -f tigera-operator.yaml ]; then
    kubectl delete -f custom-resources.yaml
  fi

  if [ -f custom-resources.yaml ]; then
    kubectl delete -f tigera-operator.yaml
  fi

  rm -f /etc/cni/net.d/10-calico.conflist
  rm -f /etc/cni/net.d/calico-kubeconfig

  ifconfig cni0 down
  ip link delete cni0
  ifconfig tunl0 down
  ip link delete tunl0

  systemctl restart kubelet
}

function f_status() {
  set -x
  kubectl get nodes
  set +x

  printf "\n"

  set -x
  kubectl get pods -n kube-system
  set +x

  printf "\n"

  set -x
  kubectl get pods -n calico-system
  set +x

  printf "\n"

  set -x
  kubectl get all -o wide
  set +x
}

function f_test() {
  echo "-- test"
  kubectl create deployment nginx --image=nginx
  kubectl expose deployment nginx --port=80 --type=NodePort
}

function f_delete_test() {
  echo "-- delete test"
  kubectl delete deployment.apps/nginx service/nginx
}

function f_help() {
  echo "Usage: bash $0 {master|node|token}"
  echo "Usage: bash $0 {check}"
  echo "Usage: bash $0 {status}"
  echo "Usage: bash $0 {flannel|delete_flannel}"
  echo "Usage: bash $0 {calico|delete_calico}"
  echo "Usage: bash $0 {test|delete_test}"
  echo "Usage: bash $0 {help}"
}

case "$1" in
  init_system)
    f_init_system
    ;;
  check_system)
    f_check_system
    ;;

  init_docker)
    f_init_docker
    ;;
  check_docker)
    f_check_docker
    ;;

  init_kubernetes)
    f_init_kubernetes
    ;;
  check_kubernetes)
    f_check_kubernetes
    ;;

  init_master)
    f_init_master
    ;;
  init_token)
    f_init_token
    ;;

  master)
    f_init_system
    printf "\n\n"
    f_init_docker
    printf "\n\n"
    f_init_kubernetes
    printf "\n\n"
    f_init_master
    printf "\n\n"
    f_init_token
    ;;
  node)
    f_init_system
    printf "\n\n"
    f_init_docker
    printf "\n\n"
    f_init_kubernetes
    ;;

  token)
    f_init_token
    ;;

  check)
    f_check_system
    printf "\n\n"
    f_check_docker
    printf "\n\n"
    f_check_kubernetes
    ;;

  flannel)
    f_init_flannel
    ;;
  delete_flannel)
    f_delete_flannel
    ;;

  calico)
    f_init_calico
    ;;
  delete_calico)
    f_delete_calico
    ;;

  status)
    f_status
    ;;

  test)
    f_test
    ;;
  delete_test)
    f_delete_test
    ;;

  help)
    f_help
    ;;

  *)
    f_help
    ;;
esac
