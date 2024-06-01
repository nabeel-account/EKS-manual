# Applying Kubernetes applications

Once the terraform infrastructure has been built, you can start deploying the application.

## test.yaml
The first application to test out connectivity between AWS IAM role and EKS service account. The ability to link the two services was created under iam-iodc.tf which created the IAM roles for service account. Here will will link the k8s application with AWS IAM roles that should already be available to use.

Once you've created the pod in test.yaml, try to list the list of S3 buckets as follows:
kubectl exec aws-cli -- aws s3api list-buckets

If you encounter the error below, it means you have not granted the right permissions to the role or the role has not be successfully assumed by the k8s service account.

```
An error occurred (AccessDenied) when calling the ListBuckets operation: Access Denied
command terminated with exit code 254
```

## deployment.tf
Create a deployment file with node affinity pointing to the node with the label key:value  role: default


## public-lb.yaml
Create a network load balancer which will automatically be provisioned in the public subnet.
The load balanacer will be created by the k8s service "loadbalancer". This service, with the help of the permissions granted to EKS in "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy" will create the NLB in AWS with the appropriate DNS name. Please allow the NLB sometime before using the DNS name as it will need privisioning.

Please check the following:
- Scheme: internet-facing
- Type: network (for network loadbalancer)
- State: Active
- Availability Zone: points to public subnets

## private-lb.yaml
You will have resources like database operator and other resources you do not share to wish to the internet. These servicse can be shared within your VPC with the load distributed using a private network load balancer. This is where this kubernetes manifest comes in handy.

What makes and distinguishes this serivce manifest from the previous is the following annotation.

```
service.beta.kubernetes.io/aws-load-balancer-internal: 0.0.0.0/0
```

This annotation ensures the loadbalancer that will be created will be internal within VPC i.e. private. This CIDR range is specifying which subnet CIDR or kubernetes service CIDR/IP can access this internet load balanacer.

## cluster-autoscaler.yaml
This will deploy the neccessary resources needed to manage and send API calls to the AWS cluster auto-scaler. The cluster autoscaler has already been authenticated under terraform, the K8S manifest authorises it to access K8S resources and have K8S resources send API calls when it need more node.

Deploy all the manifest (deployment, configmap, roles, rolebinding etc). 

Please make sure to update the following image: 
```
registry.k8s.io/autoscaling/cluster-autoscaler:v1.29.3
```

the version of the image should be the version of the EKS cluster. For example v1.29.3 is the EKS 1.29

You can find the full list of the images here: https://github.com/kubernetes/autoscaler/releases


You also need to specify the correct cluster name under --node-group-auto-discovery:
```
--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/main
```

## Test autoscaler
To test the autoscaler, increase the number of deployments in deployment.yaml e.g. from 5 to 25