# kubectl delete pod/$(kubectl get pods | grep flow-bound-agent | awk '{print $1}')

FLOW_ENVIRONMENTS="dev qa preprod"
GCP_CLUSTER_NAME=zero-point-one
ZONE=us-east1-b
GCP_PROJECT=core-flow-research

FLOW_AGENT_POD=$(kubectl get pods | grep flow-bound-agent | awk '{print $1}')
FLOW_AGENT_STATUS=$(kubectl exec $FLOW_AGENT_POD -- /opt/cbflow/health-check)
TARGET_STATUS="OK"

echo '----> Waiting for the Agent server to come online'
until [ "$FLOW_AGENT_STATUS" == "$TARGET_STATUS" ]; do 
  sleep 15;
  FLOW_AGENT_STATUS=$(kubectl exec $FLOW_AGENT_POD -- /opt/cbflow/health-check);
done

echo '----> Getting curl, git and vim'
kubectl exec $FLOW_AGENT_POD -- apt-get update
kubectl exec $FLOW_AGENT_POD -- apt-get -y install curl vim git
echo '----> Installing python3 and gcloud'
kubectl exec $FLOW_AGENT_POD -- apt-get -y install python3 apt-transport-https ca-certificates gnupg
kubectl exec $FLOW_AGENT_POD -- bash -c 'curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -'
kubectl exec $FLOW_AGENT_POD -- bash -c 'curl https://sdk.cloud.google.com > gcloud_install.sh'
kubectl exec $FLOW_AGENT_POD -- bash gcloud_install.sh --disable-prompts --install-dir=/opt
echo '----> Installing kubectl'
kubectl exec $FLOW_AGENT_POD -- bash /opt/google-cloud-sdk/bin/gcloud --quiet components install kubectl
echo '----> Setting up Flow agent kubectl authentication and contexts'
kubectl exec $FLOW_AGENT_POD -- su - cbflow -c "echo 'export PATH=\$PATH:/opt/google-cloud-sdk/bin' >> ~/.bashrc"

for env in $FLOW_ENVIRONMENTS
do
	kubectl exec $FLOW_AGENT_POD -- su - cbflow -c "\
		/opt/google-cloud-sdk/bin/gcloud container clusters get-credentials $GCP_CLUSTER_NAME --zone $ZONE --project $GCP_PROJECT && \
		/opt/google-cloud-sdk/bin/kubectl config rename-context gke_${GCP_PROJECT}_${ZONE}_${GCP_CLUSTER_NAME} $env && \
		/opt/google-cloud-sdk/bin/kubectl config set contexts.${env}.namespace $env"
done
echo '----> Agent access and test'
echo -e "kubectl exec -it $FLOW_AGENT_POD -- bash\nsu - cbflow\n\nkubectl get nodes"