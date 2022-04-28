read -n 1 -p Continue.....

if [ ! -f "reset" ]; then
    sudo su
    echo "writting new hostname...."
    echo “gorilla-master”>/etc/hostname
    touch reset
    shutdown -r now

fi


read -n 1 -p Continue.....

yum install iproute-tc -y

yum install docker -y 
systemctl enable docker && systemctl start docker


docker info | grep -i driver 
cat <<EOF >> /etc/docker/daemon.json
{ 
  "exec-opts": ["native.cgroupdriver=systemd"] 
}
EOF
systemctl restart docker
docker info | grep -i driver 



cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF


cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system
setenforce 0

yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes



systemctl restart docker

sudo su
systemctl enable kubelet && systemctl start kubelet
systemctl status kubelet  



kubeadm init  --pod-network-cidr=192.168.0.0/16 --ignore-preflight-errors=NumCPU --ignore-preflight-errors=Mem
#There is a token for the worker nodes to join the cluster that must be copied

su - ec2-user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf  $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

#The kubelet service is running until the kubedm init is executed ;)

#Installing calico
#kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
# kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
#Installing calico
curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml 

#Installing flannel
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml


