# Installing vault client

Run the below vaultclient-setup.sh script to download and place the vault binary in /usr/bin folder:
<pre>
$ git clone git@github.move.com:IT-Operations/vault-client.git 
$ cd vault-client
$ sudo ./vaultclient-setup.sh 
</pre>
Note: This script also places an environment variable "VAULT_ADDR='https://vault.moveaws.com'" in .bashrc, so you don't have to export it every time.

# Check the installation:
To verify installation, run the "vault status" command and you should see an output like the one given below:

<pre>
$ export VAULT_ADDR='https://vault.moveaws.com'
$ vault status
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0

High-Availability Enabled: false
$
</pre>

# Using vault

## Authorization using the token
In order to perform any operation in vault, you should first identify yourself by providing the token that corresponds to your app's key(s) path. 

Use the vault_auth command to do this by providing your token

Set the VAULT_TOKEN environment variable
<pre>
$export VAULT_TOKEN=728c82be-1f1c-e945-1bb9-xxxxxxx
</pre>

<pre>
$ ./vault_auth 728c82be-1f1c-e945-1bb9-xxxxxxx
vault auth -address=https://vault.moveaws.com 728c82be-1f1c-e945-1bb9-xxxxxxx
Successfully authenticated! You are now logged in.
token: 728c82be-1f1c-e945-1bb9-xxxxxxx
token_duration: 2591592
token_policies: [default, yourapp]
</pre>

Note: If you are a first time user and don't have a token, contact any of the admins of your github group listed in this wiki page(TODO: define the policy), and provide them the name of your app. They would create a policy which gives you access to your app secret path (/secret/yourapp) and give you the token that has access to that secret path. 

## Write to vault 

Assuming that you now that you have authenticated with a token that has write access to your secret path, you can issue the below command to write your secret to vault:

<pre>
$ ./vault_write_file /secret/yourapp/devapikey /Users/username/apikey
Success! Data written to: secret/yourapp/devapikey
$
</pre>

Access control policies in Vault control what a user can access.When initializing Vault, only the "root" policy is present. It gives superuser access to everything in Vault.

As we plan to store secrets for saying multiple projects, we should be able to clearly separate access to secrets that belong to different projects. And this is where policies do their job.


Policies in Vault are formatted with HCL. HCL is a human-readable configuration format that is also JSON-compatible, so you can use JSON as well. An example policy is shown below:

<pre>
path "secret/project/name" {
  policy = "read"
}
</pre>

It specify path, like we have in some tree structure, wildcards are supported.
If you provide access to specific part of the tree, you also provide the same access to all subnodes, unless you override it.

Policy is registered with *policy-write* command
<pre>
./vault_ policy-write demo demo.hcl
vault policy-write -address=http://localhost:8200 demo demo.hcl
Policy 'demo' written.
</pre>

## Deployment tokens

Now it is time to create deployment token. In our case, this is token that would allow us to read the secret deployment value from vault, and does not have any additional privileges except this.

In order to do so, we are using creating token with policy command

<pre>
./vault_create_token_with_policy demo
vault token-create -address=http://localhost:8200 -policy=demo
4d79adad-a4ec-de8b-3f85-5467b3e8536a
</pre>


## Storing data

Now it is time to store some secrets for deployment. For purposes of the demo, let it be some api key and private key used for deployment.

Command write is used to write the secrets
<pre>
./vault_write secret/project/name/apikey BLABLABLA
vault write -address=http://localhost:8200 secret/project/name/apikey value=BLABLABLA
Success! Data written to: secret/project/name/apikey

./vault_write_file secret/project/name/id_rsa ./demo_rsa
Success! Data written to: secret/project/name/id_rsa
</pre>

### Important
Binary file storing is not supported as for now, but you always can store base64 encoded file, like the MIME attachments are stored in mails.
Fortunately, for most deployments we have api keys and private keys that are text files.

## Retrieving the data

There are two ways to access your data.
First is using vault client itself

<pre>
./vault_read secret/project/name/apikey
vault read -address=http://localhost:8200 secret/project/name/apikey
Key            	Value
lease_id       	secret/project/name/apikey/a74dd189-de4b-1c98-ba24-6b29258c511b
lease_duration 	2592000
lease_renewable	false
value          	BLABLABLA

./vault_read secret/project/name/id_rsa
vault read -address=http://localhost:8200 secret/project/name/id_rsa
Key            	Value
lease_id       	secret/project/name/id_rsa/204ba657-9648-4fa5-8f82-ede992a054b4
lease_duration 	2592000
lease_renewable	false
value          	-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEApiLCR2sgf5unedMk1a2maL22PsoPwQWpGTDFZgCvhSVWvnBs
...
</pre>

second is using http based API. For that scenario you will need to authorize via deployment token we allocated previously.
<pre>
./vault_curl 4d79adad-a4ec-de8b-3f85-5467b3e8536a secret/project/name/apikey
curl -H X-Vault-Token: 4d79adad-a4ec-de8b-3f85-5467b3e8536a -X GET http://localhost:8200/v1/secret/project/name/apikey
{"lease_id":"secret/project/name/apikey/2189c6c4-1fa7-0f4d-2598-bded29a4ce6b","renewable":false,"lease_duration":2592000,"data":{"value":"BLABLABLA"},"auth":null}

./vault_curl 4d79adad-a4ec-de8b-3f85-5467b3e8536a secret/project/name/id_rsa
curl -H X-Vault-Token: 4d79adad-a4ec-de8b-3f85-5467b3e8536a -X GET http://localhost:8200/v1/secret/project/name/id_rsa
{"lease_id":"secret/project/name/id_rsa/ec509e1f-09a7-6aee-54e2-f3364720c7de","renewable":false,"lease_duration":2592000,"data":{"value":"-----BEGIN RSA PRIVATE KEY-----\nMIIEpgI......-----END RSA PRIVATE KEY-----"},"auth":null}
</pre>


# Handy Commands 

Some files just help using existing vault functionality in a more handy way:

- vault_status - gets status of the vault
- vault_policy - lists known policies, or shows details of the policy provided as a first parameter
- vault_create_token_with_policy creates and returns token with policy provided as a first parameter.
- vault_read reads secret by key (first parameter)
- vault_write writes secret by key (first parameter) and set's it's value (second parameter)
- vault_write\_file writes secret by key (first parameter) and stores content's of text file provided as second parameter
- vault_curl can be used to test http api. First parameter - access token, second parameter secret key to read
