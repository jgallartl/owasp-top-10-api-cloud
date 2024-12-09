# OWASP Top 10 API Cloud

This project aims to evaluate the effectiveness of default security mechanisms, specifically Web Application Firewalls (WAF), in Azure and AWS for protecting against Web API vulnerabilities. It utilizes the crAPI (Completely Ridiculous API) from OWASP to reproduce and test the 15 challenges proposed by the OWASP. [OWASP Top 10 API crAPI challenges](https://github.com/OWASP/crAPI/blob/develop/docs/challenges.md)

## Environments

The environments aim to reproduce some basic lift-and-shit scenarios:
* AWS with an EC2 instance and an Application Security Group
* AWS with an EC2 instance protected by an API Gateway with a WAF
* Azure with a VM instance with a Network Security Group
* Azure with a VM instance protected by an Application Gateway and a WAF

Note: Preconfigured options have been used in WAF instances:
- Pre-defined available Managed Rules for AWS WAF
- OWASP 3.2 web configuration for Azure WAF


## Software Requirements
* Python 3.12
* Terraform

## Account Requirements
You need to install and configure Azure and AWS CLI and:
* An Azure free account with a small credit to run Azure scenarios
* An AWS free account with a small credit to run AWS scenarios

## Other
Create an SSH key to access VMs for troubleshooting
```
ssh-keygen -f  ~/.ssh/id_rsa_crapi
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa_crapi
```

## How to run

### 1. Clone the Repository
```bash
git clone https://github.com/jgallartl/owasp-top-10-api-cloud.git
cd owasp-top-10-api-cloud
```

### 2. Change Directory to the Environment You Want to Test
Navigate to the directory containing the Terraform configuration files.

### 3. Deploy the Environment
Initialize Terraform, plan the deployment, and apply the plan:
```
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### 4. Refresh the Output
Once the deployment is finished, refresh the output to get the DNS name of the instance. You might need to wait a couple of minutes for the web to be available:
```
terraform refresh
```

### 5. Run the Tests
Navigate to the test directory and run the tests using the DNS name obtained in the previous step:
```
python crapi_test.py --ip <DNS name displayed in the previous step>
```

### 6. Clean up resources
Once you have finished avoid unnecesary costs destroying the created environment
```
terraform destroy
```


## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

