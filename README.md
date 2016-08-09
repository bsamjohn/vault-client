Using Vault by HashiCorp to secure your deployment secrets
=======================================

# Installing Manually

Formal installation steps are covered by this article: [https://vaultproject.io/docs/install/](https://vaultproject.io/docs/install/)
Run the below setup.sh script that installs vault into /opt/ folder , configures it to listen on localhost port 8200 and registers it as a service called vault-server
<pre>
$git clone git@github.move.com:bsamjohn/move-vault.git
$cd move-vault 
$sudo ./setup.sh
</pre>


# Check the installation:
<pre>
$vault status
Error checking seal status: Error making API request.

URL: GET http://localhost:8200/v1/sys/seal-status
Code: 400. Errors:

* server is not yet initialized
</pre>
Message means, that vault was installed and configured correctly, but needs to be initialized. Initialization happens once when the server is started against a new backend that has never been used with Vault before. During initialization, the encryption keys are generated, unseal keys are created, and the initial root token is setup. To initialize Vault use vault init. This is an unauthenticated request, but it only works on brand new Vaults with no data

Let's init. Important influence on security has number of key shares to generate and number of key shares provided to unlock the seal.

How does it work: the key used to encrypt the data is also encrypted using 256-bit AES in GCM mode. This is known as the master key. The encrypted encryption key is stored in the backend storage. The master key is then split using Shamir's Secret Sharing. Shamir's Secret Sharing ensures that no single person (including Vault) has the ability to decrypt the data. To decrypt the data, a threshold number of keys (by default three, but configurable) are required to unseal the Vault. Thesekeys are expected to be with three different places / individuals.

It has full analogy to secure bank cell where one key has bank personnel and one is yours.In case of vault you might have much higher level of security.

<pre>
$cd utils
$ ./vault_auth <Initial Root Token>
The number of key shares to split the master key into: 1
The number of key shares required to reconstruct the master key 1
Key 1: a1b2c3d4e5f6g7h8j9k10l11m12n13o14p15q16r17s18t19u20v21w22x23y24z26
Initial Root Token: 98df443c-65ee-d843-7f4b-9af8c426128a

Vault initialized with 1 keys and a key threshold of 1!

Please securely distribute the above keys. Whenever a Vault server
is started, it must be unsealed with 1 (the threshold) of the
keys above (any of the keys, as long as the total number equals
the threshold).

Vault does not store the original master key. If you lose the keys
above such that you no longer have the minimum number (the
threshold), then your Vault will not be able to be unsealed.
</pre>

Initial Root Token must be immediately saved in a secure location.

# Using vault

## Unsealing
When a Vault server is started, it starts in a sealed state. Unsealing is the process of constructing the master key necessary to read the decryption key to decrypt the data, thus prior to unsealing, almost no operations are possible with Vault.

Let's unseal:
<pre>
./vault_unseal Unseal_Key
Sealed: false
Key Shares: 1
Key Threshold: 1
Unseal Progress: 0
</pre>

Note, if you had higher threshold set, all the key holders would need to perform unseal operation with their parts of the key.  That's provides additional level of security for accessing the data

## Authorization
In order to continue working with vault, you should first identify yourself.
Let's use auth command to do this by providing our initial root token

<pre>
./vault_ auth 98df443c-65ee-d843-7f4b-9af8c426128a
Successfully authenticated! The policies that are associated
with this token are listed below:

root

</pre>

## Policies

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
