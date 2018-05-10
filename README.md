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

## Authorization using the okta
In order to perform any operation in vault, you should first identify yourself by providing the token that corresponds to your app's key(s) path. 

Set the VAULT_ADDR environment variable
<pre>
$export VAULT_ADDR=https://vault.moveaws.com
</pre>

Use the vault auth command
<pre>
$ vault auth --method=okta username=bsamjohn
Password (will be hidden): youroktatoken
Successfully authenticated! You are now logged in.
The token below is already saved in the session. You do not
need to "vault auth" again with the token.
token: xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxx
token_duration: 2764799
token_policies: [default, yourapp]
</pre>

## Write to vault 

Assuming that you now that you have authenticated with a token that has write access to your secret path, you can issue the below command to write your secret to vault:

<pre>
$ ./vault_write_file /secret/girthuborg/yourapp/dev/somesecret /Users/username/secretvaluefile
Success! Data written to: /secret/girthuborg/yourapp/dev/somesecret
$
</pre>

## Read your secret!

There are two ways to access your data.
First is using vault client itself

<pre>
./vault_read secret/yourapp/devapikey
vault read -address=https://vault.moveaws.com /secret/girthuborg/yourapp/dev/somesecret
Key            	Value
lease_id       	secret/girthuborg/yourapp/dev/somesecret/xxxxxx-xxx-xxx-x-xxxxxxx
lease_duration 	2592000
lease_renewable	false
value          	BLABLABLA

./vault_read secret/yourapp/devapikey/id_rsa
vault read -address=https://vault.moveaws.com secret/yourapp/devapikey/id_rsa
Key            	Value
lease_id       	secret/yourapp/devapikey/id_rsa/xxxxxx-xxx-xxx-x-xxxxxxx
lease_duration 	2592000
lease_renewable	false
value          	-----BEGIN RSA PRIVATE KEY-----
MIIEpgIBAAKCAQEApiLCR2sgf5dMk1a2maL22PsoPwQWpGTDFZgCvhSVWvnBs
...
</pre>

The second method is using http based API. For that scenario you will need to authorize via deployment token we allocated previously.
<pre>
./vault_curl 728c82be-1f1c-e945-1bb9-xxxxxxx secret/yourapp/devapikey
curl -H X-Vault-Token: 4d79adad-a4ec-de8b-3f85-5467b3e8536a -X GET http://localhost:8200/v1/secret/project/name/apikey
{"lease_id":"secret/yourapp/devapikey/xxxxxx-xxx-xxx-x-xxxxxxx","renewable":false,"lease_duration":2592000,"data":{"value":"BLABLABLA"},"auth":null}
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
