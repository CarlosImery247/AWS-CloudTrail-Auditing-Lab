# Investigation commands

Placeholders: `<bucket>` is your CloudTrail bucket, `<region>` is your region.

## Download and unpack the logs
```bash
mkdir ctraillogs && cd ctraillogs
aws s3 ls
aws s3 cp s3://<bucket>/ . --recursive
gunzip $(find . -name '*.gz')
```

## Search with grep
```bash
for i in $(find . -name '*.json'); do echo $i && python3 -m json.tool $i | grep sourceIPAddress; done
for i in $(find . -name '*.json'); do echo $i && python3 -m json.tool $i | grep eventName; done
```

## Search with the AWS CLI
```bash
aws cloudtrail lookup-events --region <region> \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin

sgId=$(aws ec2 describe-instances --region <region> \
  --filters "Name=tag:Name,Values='Cafe Web Server'" \
  --query 'Reservations[*].Instances[*].SecurityGroups[*].[GroupId]' --output text)

aws cloudtrail lookup-events --region <region> \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::EC2::SecurityGroup \
  --output text | grep $sgId
```

## Respond on the instance
```bash
sudo aureport --auth          # who logged in
who                           # who is logged in now
sudo userdel -r <user>        # reports the blocking process id
sudo kill -9 <pid>
sudo userdel -r <user>
sudo cat /etc/passwd | grep -v nologin
sudo vi /etc/ssh/sshd_config  # set PasswordAuthentication no
sudo service sshd restart
```
