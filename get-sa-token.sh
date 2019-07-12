SA_NAME=logreader
SECRET=$(kubectl get sa ${SA_NAME} -n kube-system -o jsonpath="{.secrets[].name}")
TOKEN=$(kubectl get secret ${SECRET} -n kube-system -o go-template='{{index .data "token"}}' | base64 --decode)
echo "$TOKEN"