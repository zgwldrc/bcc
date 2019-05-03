SA_NAME='deploy-patcher'
NAMESPACE=$(kubectl get sa default -ojsonpath='{.metadata.namespace}')
function create_cluster_deploy_patcher_sa() {
    local sa_name=$SA_NAME
    kubectl -n kube-system create sa $sa_name
    kubectl create clusterrole $sa_name --resource=deploy --verb=patch --verb=get
    kubectl create clusterrolebinding $sa_name --clusterrole=$sa_name --serviceaccount=kube-system:$sa_name
}
function get_sa_token(){
    local sa=$SA_NAME
    # 根据SA得到Secret
    local secret=$(kubectl -n kube-system get sa $sa -ojsonpath="{.secrets[0].name}")
    # 根据Secret得到Token
    kubectl -n kube-system get secret $secret -o jsonpath="{['data']['token']}"|base64 -D
}
function gen_sa_kubeconfig(){
    local token=$(get_sa_token)
    local certificate_authority_data=$(kubectl get secret `kubectl get secrets | egrep -o 'default-token-[a-z0-9]+'` -o jsonpath="{['data']['ca\.crt']}")
    local api_server=$(kubectl cluster-info|grep master|grep -Eo 'https://[a-zA-Z0-9.:-]+')
    local kubeconfig=$(mktemp)
    {
        kubectl config --kubeconfig=$kubeconfig set-cluster default --server=$api_server
        kubectl config --kubeconfig=$kubeconfig set clusters.default.certificate-authority-data $certificate_authority_data
        kubectl config --kubeconfig=$kubeconfig set-credentials $SA_NAME --token=$token
        kubectl config --kubeconfig=$kubeconfig set-context default --cluster=default --user=$SA_NAME --namespace=$NAMESPACE
        kubectl config --kubeconfig=$kubeconfig use-context default
    } > /dev/null
    cat $kubeconfig
    rm -f $kubeconfig
}
function clean_deploy_patcher_sa(){
    local sa_name=$SA_NAME
    kubectl delete clusterrolebinding $sa_name
    kubectl delete clusterrole $sa_name
    kubectl -n kube-system delete sa $sa_name
}
create_cluster_deploy_patcher_sa
gen_sa_kubeconfig > kubeconfig

# kubectl get deploy 
# kubectl --kubeconfig=kubeconfig get deploy staff-web

