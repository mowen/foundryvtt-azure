# Running Foundry Virtual Table Top in a Local/Remote Docker Container

Requires the following envirionment variables to be defined in your Circle CI Project Settings:

## Azure RM Service Principal Credentials

Run the following Az CLI command to generate a Service Principal:

```shell
az ad sp create-for-rbac --scopes /subscriptions/<Subscription ID> --name <Service Principal Name>
```

More info: <https://learn.microsoft.com/en-us/cli/azure/create-an-azure-service-principal-azure-cli>

- ARM_CLIENT_ID
- ARM_CLIENT_SECRET
- ARM_TENANT_ID
- ARM_SUBSCRIPTION_ID

## Foundry VTT Authentication and License Key

- TF_VAR_FOUNDRY_ADMIN_KEY
- TF_VAR_FOUNDRY_PASSWORD
- TF_VAR_FOUNDRY_USERNAME
- TF_VAR_FOUNDRY_LICENSE_KEY
