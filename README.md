# Windows Virtual Desktop Reference Architecture

This collection is for Windows Virtual Desktop Deployment

Click the button below to deploy of hub and spoke infrastructure with Azure Firewall Premium

Recommend # of VM = 1 for testing

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2ftakeokams%2fwvd-reference-architecture%2fmain%2fazuredeploy.json)

Click the button below to deploy of 2 new Windows VMs, a new AD Forest, Domain, 2 DCs and AD Certificate Service with Enterprise Root CA for AFW Prem TLS Inspection in separate availability zones.
This template is designed for existing vnet (previously created above)

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3a%2f%2fraw.githubusercontent.com%2ftakeokams%2fwvd-reference-architecture%2fmain%2faddeploy.json)
