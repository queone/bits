---
type: reference
---
## AWS
Amazon Web Services bits.

### Account Setup
What the new sign-up flow gives you, where the Free plan stops, and the account shape that activation leaves behind. Checked against the AWS docs in October 2026.

- Signing up with a [Builder ID](https://docs.aws.amazon.com/signin/latest/userguide/sign-in-aws_builder_id.html) creates one project account on the Free plan, outside any organization and with no root user. AWS names it "Index Zero", which means nothing, and the management account can rename it later from Organizations.
- The Free plan's [managed guardrail policy](https://docs.aws.amazon.com/accounts/latest/reference/scps-and-rcps-for-projects.html) denied what a small host needs. Systems Manager for administration without SSH, the EC2 lookups behind it, and Identity Center were all withheld.
- The only way past it is the paid plan followed by [advanced features](https://docs.aws.amazon.com/accounts/latest/reference/activate-advanced-features.html). The paid plan alone does not lift the guardrail, and neither step can be reversed.
- Activation turns the one account into an organization of three. A management account pays the bills and owns the policies. An identity account administers Identity Center. The original account becomes the project account, where workloads go.
- Activation creates a root email and password for the management account. The project account still has none. Expect the change, since the sign-up had no root user at all.
- Activation also removes any spend limit set during the upgrade. A Budget in the management account takes its place, and a Budget alerts but does not cap.
- Regions are assigned, not chosen. A US address puts the project in `us-east-2`, and the region guardrail denies regional services such as EC2, Systems Manager, and S3 anywhere else.
- `us-east-1` stays allowed for global services only, such as IAM, Route 53, STS, and Budgets. `us-west-2` stays allowed for a handful, such as Bedrock and Support. To add a region, edit the `RegionFloor` statement of the guardrail policy.
- The same guardrail denies SNS and CloudWatch alarms in `us-east-1`, which a Route 53 health check needs. Add `cloudwatch:PutMetricAlarm`, `cloudwatch:DeleteAlarms`, `cloudwatch:TagResource`, and `sns:*` to the `NotAction` list of the `UsEast1Partitional` statement. Expect AWS to rewrite the policy on a plan or mode change, and repeat the edit then.
- Sign in at the console as the Builder ID user and pick an account on the sessions page. The access portal lists no accounts, since sessions come through the organization rather than permission sets.
- On the command line use `aws login --profile <NAME>`. `aws configure sso` cannot see this model.
- [attune](https://github.com/queone/attune) reconciles a host in this account shape. Its README describes the shape and warns when a spec names `us-east-1`.

### AWS EC2 Instance Types Comparison
See <https://instances.vantage.sh/>

### Useful Commands
Useful commands.

- EC2 instance metadata, from instance: `curl -s http://169.254.169.254/latest/meta-data/ ec2`

- Get AWS Instances ID: `InstId=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>&1)`

