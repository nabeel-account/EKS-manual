# EKS-manual

This is a manual production of EKS

## 5-iam-eks-resources-role.tf
Create an IAM role which the EKS pods/resources will utilise through the use of EKS service account.
The IAM role needs to have the appropriate IAM policies for it to function as desired.

## 6-iam-autoscaler.tf
This is where we create the necessary IAM Role and IAM policy (permssions) to autoscale incoming EKS load. The management of the autoscaler will be by K8S autoscaler resources. The K8S autoscaler resource will inherate the permissions to interact with AWS autoscaler using the role provisioned in 6-iam-autoscaler and assumed by the K8S autoscaler service account.


## Once you've created your cluster
- Ensure your IAM user, which created the EKS, has admin permissions by checking IAM access entries under Access in the cluster's dashboard.

- Ensure the EKS cluster nodes are created under private subnets by accessing Subnets under Networking in the cluster's dashboard.

- Please make sure you are the IAM user discovered above.
```
aws sts get-caller-identity
```

- Update your kubeconfig with the appropriate access EKS credentiails provided to the IAM user
```
aws eks update-kubeconfig --region <AWS REGION> --name <CLUSTER NAME>
```

- Ensure you have admin permissions
```
kubectl auth can-i "*" "*"
```

## More info
Please read through lesson 102: https://github.com/antonputra
https://www.youtube.com/watch?v=MZyrxzb7yAU&list=PLiMWaCMwGJXkeBzos8QuUxiYT6j8JYGE5&index=8