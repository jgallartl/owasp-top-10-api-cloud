# owasp-top-10-api-azure

ssh-keygen -f  ~/.ssh/id_rsa_crapi
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa_crapi

https://zerodayhacker.com/crapi-walkthrough-using-ai/

https://github.com/Azure/terraform/blob/master/quickstart/101-application-gateway/main.tf


sudo cat /var/log/cloud-init-output.log

https://danaepp.com/writing-api-exploits-in-python


Integration of Azure API Management with Application Gateway
API Gateway: Azure Application Gateway acts as a Layer-7 load balancer and a Web Application Firewall (WAF). It receives incoming HTTP requests and routes them to the appropriate backend services2.

Security: The WAF component of Application Gateway provides protection against common web vulnerabilities and attacks. It can filter and monitor HTTP requests before they reach your backend services2.

Routing: Application Gateway can be configured with URL-based routing rules to direct traffic to different backend pools based on the URL path. For example, you can route requests to APIM for API management and to other services for different types of traffic2.

API Management: Azure API Management provides a comprehensive API gateway, management platform, and developer portal. It manages API requests, enforces policies, transforms requests and responses, and provides analytics and monitoring3.

Example Workflow
Incoming Request: A client sends an HTTP request to the Application Gateway.

WAF Filtering: The Application Gateway WAF checks the request against its rules.

Routing: If the request is valid, Application Gateway routes it to the appropriate backend pool based on the URL path.

API Management: The request is forwarded to Azure API Management, which applies additional policies, transforms the request, and routes it to the backend service3.

Backend Response: The backend service processes the request and sends a response back through API Management and Application Gateway to the client.

Benefits
Enhanced Security: Combining APIM with Application Gateway provides multiple layers of security, protecting your APIs from various threats.

Scalability: Application Gateway can handle high traffic loads and distribute requests efficiently.

Centralized Management: APIM provides a single point of management for all your APIs, simplifying administration and monitoring.

Would you like more detailed steps on setting this up, or do you have any specific questions about the integration?

terraform graph -type=plan | dot -Tpng >graph.png

Otro: https://adile1coder.medium.com/performing-security-testing-with-owasp-zap-api-and-python-b37fb59a19fa

docker rm -vf $(docker ps -aq)
docker rmi -f $(docker images -aq)



docker-compose stop
docker rm -vf $(docker ps -aq)
docker rmi -f $(docker images -aq)
docker volume rm $(docker volume ls -q)
docker-compose pull
docker-compose -f docker-compose.yml --compatibility up -d

https://github.com/arainho/awesome-api-security