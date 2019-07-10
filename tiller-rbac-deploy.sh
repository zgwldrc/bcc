tmp=$(mktemp)
cat > $tmp <<-EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF
kubectl apply -f $tmp
helm init --service-account tiller --history-max 10
rm -f $tmp

secret=$(kubectl get sa tiller --namespace=kube-system -ojsonpath='{.secrets[0].name}')
kubectl --namespace=kube-system get secret $secret -ojsonpath='{.data.token}'  | base64 -D;echo
