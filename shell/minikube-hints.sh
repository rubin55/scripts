#!/bin/sh

echo '# Remove old minikube configuration:'
echo 'rm -rf ~/.minikube'
echo ''

echo '# Configure minikube:'
echo 'minikube config set profile kube'
echo 'minikube config set driver vmware'
echo 'minikube config set memory 6144'
echo 'minikube config set disk-size 24576'
echo 'minikube config set cpus 2'
echo 'minikube config set kubernetes-version v1.16.3'
echo ''

echo '# Start minikube instance:'
echo 'minikube start --extra-config=kubeadm.node-name=kube --extra-config=kubelet.hostname-override=kube --insecure-registry "10.0.0.0/24"'
echo ''

echo '# Enable minikube registry add-on:'
echo 'minikube addons enable registry'
echo 'kubectl port-forward --namespace kube-system <name of the registry vm> 5000:5000'
echo 'docker run --rm -it --network=host alpine ash -c "apk add socat && socat TCP-LISTEN:5000,reuseaddr,fork TCP:$(minikube ip):5000"'
echo ''

echo '# Enable minikube ingress add-on:'
echo 'minikube addons enable ingress'
echo ''

echo '# Enable minikube ingress-dns add-on:'
echo 'minikube addons enable ingress-dns'
echo ''

echo '# Set up minikube ingress-dns add-on:'
echo '# See https://github.com/kubernetes/minikube/tree/master/deploy/addons/ingress-dns'
echo 'cat /etc/resolver/minikube-kube-test
domain test
nameserver 10.10.11.3
search_order 1
timeout 5'
echo ''

echo '# Make sure getty reflects hostname changes:'
echo 'minikube ssh "sudo pkill getty"'
echo ''

echo '# Set minikube docker environment variables:'
echo 'eval `minikube docker-env`'
echo ''
