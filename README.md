
# INFRASTRUCTURE AS CODE

Setting up infrastructure in AWS

## Installations

Install terraform using the following commands:
```
mkdir software
cd software
wget https://releases.hashicorp.com/terraform/0.12.24/terraform_0.12.24_linux_amd64.zip
unzip terraform_0.12.24_linux_amd64.zip
cd 
vim .profile
```

Edit the .profile file and add the following to the end of the file: 

``` export PATH="$PATH:~/software" ``` 
<br />
Lastly check if terraform is installed successfully:
``` 
terraform version 
```

## Configure AWS
Configure your IAM users using the following command: 

``` 
aws configure --profile dev 
```
```	
aws configure --profile prod 
```

## Terraform commands to create a VPC

- Running Terraform for the first time:
	- ``` terraform init  ``` 
- After the first time,
	- ``` terraform plan ```
- To apply and create VPC
	- ``` terraform apply ```
- To destroy the VPC
	- ``` terraform destroy ``` 
