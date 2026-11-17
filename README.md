# AWS Lab: Auditing an Incident with AWS CloudTrail and Athena

Hands-on lab completed on **16 Nov 2026** (us-west-2, with some logs in us-east-1). Scenario: a cafe's website was defaced and someone opened SSH to the world on its security group. I enabled CloudTrail, then investigated with `grep`, the AWS CLI and Amazon Athena, and finally cleaned up the instance and the AWS account.

> Screenshots have been redacted (account IDs, resource IDs, IP addresses, ARNs, bucket names and usernames are blurred). The original lab guide is AWS training material and is not reproduced here; this repo contains my own notes and queries.

## Summary

| Phase | What I did |
|-------|-----------|
| Baseline | Added an SSH rule limited to my own IP and checked the website looked normal |
| Detection | Created the `monitor` trail (multi-region, KMS-encrypted S3 bucket); the site was then defaced and a world-open SSH rule appeared |
| Investigation | Downloaded the logs and searched them with `grep`, `aws cloudtrail lookup-events`, then Athena SQL |
| Response | Found an unexpected `chaos-user` OS login, killed the session, removed the account, hardened `sshd_config`, removed the open SSH rule, restored the image, deleted the `chaos` IAM user |

Reusable material: [`queries/athena-queries.sql`](queries/athena-queries.sql) and [`commands/investigation-commands.md`](commands/investigation-commands.md).

## Walkthrough

### 1. Baseline and trail creation

**Cafe Web Server instance and its security group**

![Cafe Web Server instance and its security group](images/01-instances-security-tab.png)

**Adding an SSH rule restricted to my own IP (/32)**

![Adding an SSH rule restricted to my own IP (/32)](images/02-edit-inbound-rules-ssh.png)

**Cafe website before the incident**

![Cafe website before the incident](images/03-cafe-website-normal.png)

**Creating the `monitor` trail with a new S3 bucket and KMS alias**

![Creating the `monitor` trail with a new S3 bucket and KMS alias](images/04-cloudtrail-create-trail.png)

**Trail created (multi-region, us-west-2 home)**

![Trail created (multi-region, us-west-2 home)](images/05-cloudtrail-trail-created.png)


### 2. The incident

**Cafe website after the incident (defaced image)**

![Cafe website after the incident (defaced image)](images/06-cafe-website-hacked.png)

**Security group now has an extra SSH rule open to 0.0.0.0/0**

![Security group now has an extra SSH rule open to 0.0.0.0/0](images/07-security-group-ssh-open.png)


### 3. Investigating with grep and the AWS CLI

Connected over SSH, downloaded and unzipped the logs, then filtered them.

**SSH session on the web server**

![SSH session on the web server](images/08-ssh-session.png)

**Downloading the CloudTrail logs with `aws s3 cp` (first attempt had a bucket-name typo)**

![Downloading the CloudTrail logs with `aws s3 cp` (first attempt had a bucket-name typo)](images/09-s3-download-logs.png)

**Navigating the downloaded log directory**

![Navigating the downloaded log directory](images/10-logs-directory.png)

**Filtering log files for `sourceIPAddress`**

![Filtering log files for `sourceIPAddress`](images/11-grep-sourceipaddress.png)

**Listing every `eventName` across the log files**

![Listing every `eventName` across the log files](images/12-grep-eventname.png)

**Logs in the us-east-1 directory**

![Logs in the us-east-1 directory](images/13-grep-us-east-1.png)

**Setting the region manually and retrieving the security group ID**

![Setting the region manually and retrieving the security group ID](images/14-region-and-sgid.png)

**`aws cloudtrail lookup-events` filtered by security group (fully blurred: raw JSON is full of IDs and keys)**

![`aws cloudtrail lookup-events` filtered by security group (fully blurred: raw JSON is full of IDs and keys)](images/15-lookup-events-security-group.png)


### 4. Investigating with Athena

**Athena editor and the new table**

![Athena editor and the new table](images/16-athena-editor.png)

**Setting the Athena query result location**

![Setting the Athena query result location](images/17-athena-query-result-location.png)

**Creating the Athena table from CloudTrail event history**

![Creating the Athena table from CloudTrail event history](images/18-athena-create-table.png)

**First query: `SELECT * ... LIMIT 5`**

![First query: `SELECT * ... LIMIT 5`](images/19-athena-select-all.png)

**Narrowed query on user, time, source, event name and parameters**

![Narrowed query on user, time, source, event name and parameters](images/20-athena-select-columns.png)

**Filtering EC2 events whose name contains `Security`**

![Filtering EC2 events whose name contains `Security`](images/21-athena-security-events.png)


### 5. Response and hardening

**`aureport --auth` shows an unexpected `chaos-user` login**

![`aureport --auth` shows an unexpected `chaos-user` login](images/22-aureport-auth.png)

**Killing the session and deleting the `chaos-user` OS account**

![Killing the session and deleting the `chaos-user` OS account](images/23-remove-chaos-user.png)

**Checking `/etc/passwd` for other login-capable users**

![Checking `/etc/passwd` for other login-capable users](images/24-passwd-check.png)

**Reviewing `sshd_config`**

![Reviewing `sshd_config`](images/25-sshd-config.png)

**Editing the inbound rules to remove the world-open SSH rule**

![Editing the inbound rules to remove the world-open SSH rule](images/26-remove-open-ssh-rule.png)

**Cafe website restored**

![Cafe website restored](images/27-cafe-website-restored.png)

**Deleting the `chaos` IAM user**

![Deleting the `chaos` IAM user](images/28-delete-iam-user.png)


## Challenge findings

Fill these in from your own Athena results before publishing (I did not redact-and-copy them from the lab):

- IAM user who changed the security group: `<fill in>`
- Time of the change (UTC): `<fill in>`
- Source IP: `[redacted]`
- Method (console or programmatic): `<fill in>`

## Troubleshooting and lessons learned

- **Wrong region gave empty CLI results.** The default region variable was not set, so the `lookup-events` and `describe-instances` commands returned nothing. Hard-coding `--region us-west-2` fixed it. I also found log files under `us-east-1`, since the trail is multi-region.
- **Typo in the bucket name** caused a `NoSuchBucket` error on the first `aws s3 cp`; the table name in Athena inherits that spelling.
- **Athena query result location** moved in the console: *Query editor > Query settings > Manage*.
- Searches for security group rules by an unfamiliar principal were the strongest lead; querying `eventname LIKE '%Security%'` on `ec2.amazonaws.com` narrowed the results quickly.
- Defense in depth: restricting SSH to a /32, disabling password auth, deleting stale IAM users and keeping CloudTrail on all matter together.

## Repo layout

```
.
├── README.md
├── commands/investigation-commands.md
├── queries/athena-queries.sql
└── images/            # redacted screenshots, numbered in walkthrough order
```
