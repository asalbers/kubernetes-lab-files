#!/usr/bin/bash

CleanUp(){
    read -p "Clean Up"
    kubectl delete deploy -l scope=demo
    kubectl label node $selectedNode color-
    kubectl label node $selectedNode allowedprocess-
    kubectl taint node $selectedNode onlyprocess-
}

# Change to the demo folder
cd TaintsTolerations


read -p "Navigate to the Settings page"
read -p "Turn ON Mini or Micro Pods"
read -p "Navigate to the Nodes page" 
echo

read -p "Next Step - Creates initial workloads" 
kubectl apply -f workload-1.yaml -f workload-2.yaml -f workload-3.yaml
echo

read -p "Enter the Node Name of one node" selectedNode
echo $selectedNode
 aks-agentpool-31289776-vmss000004
read -p "Next Step - Adds color and Process label to Node" 
kubectl label node $selectedNode color=lime --overwrite
kubectl label node $selectedNode allowedprocess=gpu --overwrite
echo

read -p "Notice the color box appear in the Node"

read -p "Next Step - Adds Node Selector to Lime deployment" 
kubectl apply -f workload-1-node-selector.yaml
echo

read -p "Wait for all the Lime pods to be rescheduled on the selected node" 
echo

read -p "Next Step - Adds Taint to Node"
kubectl taint node $selectedNode onlyprocess=gpu:NoSchedule
echo

read -p "Delete all the Pods on the Node" 
kubectl delete pods --field-selector=spec.nodeName=$selectedNode
echo

read -p "Wait for ALL pods to be evicted from selected node" 
echo

read -p "Observe how Lime pods cannot be scheduled.  Examine their events" 
echo

read -p "Next Step - Adds Toleration to Lime deployment" 
kubectl apply -f workload-1-toleration.yaml

read -p "Observe how only the Lime pods are scheduled on selected node and all others are on other nodes" 
echo

CleanUp
