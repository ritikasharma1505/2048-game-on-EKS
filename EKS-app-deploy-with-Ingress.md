### End-to-End project on AWS EKS (ELASTIC KUBERNETES SERVICE) WITH INGRESS - 2048 Game

EKS ?

- Allows you to run Kubernetes clusters in the cloud without needing to manually manage the underlying infrastructure.
- EKS simplifies the deployment, management, and scaling of containerized applications using Kubernetes.


WHY EKS ?
- Infrastructure Management Overhead: Running Kubernetes yourself means you have to manage the servers, networking, and storage. With EKS, AWS handles the Kubernetes control plane, so you don't need to worry about that.

- Scalability and Availability: EKS automatically adjusts your Kubernetes clusters based on traffic, ensuring your apps can scale up or down as needed without manual intervention.

- Security and Compliance: EKS integrates with AWS security tools (like IAM, VPC, and KMS) to protect your workloads. AWS also keeps the control plane updated, reducing security risks.

- Simplified Operations: EKS works smoothly with other AWS services, making it easier to build and manage cloud-native apps. It also handles things like cluster upgrades and self-healing, reducing your workload.

- Cost Efficiency: EKS takes care of the complex control plane, so you can focus on your applications and spend less time managing infrastructure, saving you both time and money.


### Deploy 2048 game on EKS with Ingress

*PRE-REQUISITES*

- install kubectl ~ command-line tool used to interact with Kubernetes clusters

- install eksctl ~ command-line utility to manage EKS cluster

- install AWS CLI: Requires ~ Access key and Access ID (Create from AWS IAM | Security Credentials)
   
    ```
    aws configure
    ```


**STEPS TO DEPLOY**

- Install AWS CLI, kubectl and eksctl, install from respective official documentation( and ignore below script)  or else use below bash script give permission and run script
    
    ```
    chmod +x install-prerequisites.sh
    ./install-prerequisites.sh

    ```

- create EKS cluster: (Replace clustername and region according to your choice)

    ```
    eksctl create cluster --name demo-eks-cluster --region us-east-1 --fargate  

    ```

- configure kubectl for EKS ~ Below command updates your local kubeconfig file with the correct context and credentials for your EKS cluster, kubectl uses this configuration to perform actions against the cluster.
   
    ```
    aws eks update-kubeconfig --name demo-eks-cluster --region us-east-1
    kubectl get nodes
    ```

- create fargate profile:
   
    ```
    eksctl create fargateprofile \
    --cluster demo-eks-cluster \
    --region us-east-1 \
    --name alb-sample-app \
    --namespace game-2048
    ```

- Deploy the deployment, service and Ingress:
   
    ```
    kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/examples/2048/2048_full.yaml
    ```

    ```
    kubectl get pods -n game-2048 -w
    kubectl get svc -n game-2048 
    kubectl get ingress -n game-2048
    ```

- Configure OIDC provider: ~ required when setting up Amazon EKS clusters to enable IAM (Identity and Access Management) roles for service accounts within Kubernetes.
    
    ```
    eksctl utils associate-iam-oidc-provider --cluster demo-eks-cluster --approve
    ```

- Download IAM policy, create IAM policy, IAM Role and ServiceAccount:
    
    ```
    curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
    ```

    ```
    aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json
    ```

    ```
    eksctl create iamserviceaccount \
  --cluster=demo-eks-cluster \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<your-aws-account-id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
    ```

NOTE : Replace AWS account ID 

- Install ALB controller:  pod - access to aws services such as ALB

    ```
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update eks
    ```

    ```
     helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \     --set clusterName=demo-eks-cluster \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set region=us-east-1 \
     --set vpcId=<your-vpc-id>
    ```

NOTE : Replace VPC Id, clusterName and region 


- Verify deployments are running:
   
    ```
    kubectl get deployment -n kube-system aws-load-balancer-controller
    ```

    ```
    kubectl get ingress -n game-2048
    ```
NOTE : check for the "ADDRESS", this is the DNS name of ALB created by ALB controller

- Access the 2048-game app, hit on browser the dns name of ALB:
 
 ```
    http://<alb-dns-name>
 ```

- Donot forget to delete the eks cluster, otherwise will have to incur costs:
 
 ```
 eksctl delete cluster --name demo-eks-cluster --region us-east-1
 ```


### Troubleshooting steps 

- due to existing serviceAccount, added a parameter when you encounter error, use the same one (happended because of stale resources remains to the trainer)
- or, go to cloudFormation  and delete the service Account stack created and delete stack
- create a new serviceAccount with new name 
- delete the helm chart, if "cannot re-use a name that is still in use" error occurs and re-run the command "helm install .."

```
kubectl edit deploy/aws-load-balancer-controller -n kube-system
kubectl get deploy -n kube-system
kubectl get pods -n kube-system
```


### Encountered new keywords:

1. CoreDNS is particularly useful in environments where dynamic service discovery is crucial,
    - CoreDNS serves as the default DNS server for Kubernetes environments 
    - Automatically managing DNS entries for services and pods.


2. Service Account
    - a Service Account is an identity for processes running within a pod, allowing those processes to interact with the Kubernetes API and other resources.


3. OIDC provider
    - service accounts are used to grant identities to applications (pods) running inside the cluster. However, Kubernetes does not natively handle AWS IAM roles or permissions.
    - OIDC provider bridges this gap by enabling a way to associate a Kubernetes service account with an IAM role. This     allows pods in the cluster to assume that IAM role and access AWS resources securely, without needing AWS access keys hardcoded in the pods.
        - Create an IAM role with a policy that grants access to specific AWS resources (e.g., S3, DynamoDB).
        - Attach the role to a Kubernetes service account.
        - Use OIDC to authenticate the service account to assume the IAM role when a pod requests access to AWS resources.

    - OIDC allows pods to authenticate directly with AWS by assuming IAM roles dynamically without needing static credentials.
    - When using IAM roles with OIDC, the permissions for a pod are temporary (short-lived credentials), which reduces the risk associated with long-lived access keys


    
    Big thanks to Abhishek Veeramalla for his guidance through video tutorial !!
    
    
    *Happy Learning !!*