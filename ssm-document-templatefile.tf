resource "aws_ssm_document" "t-document" {
  name          = "SGDocument"
  document_type = "Automation"
  document_format = "JSON"

  content    = templatefile("${path.module}/internet-SG.json.tpl",
    {
      SecurityGroupId      = local.SecurityGroupId 
      AutomationAssumeRole = local.AutomationAssumeRole
       
    })
}

ssm document
{
  "schemaVersion": "0.3",
  "parameters": {
    "SecurityGroupId": {
      "type": "String",
      "description": "(Required) The security group ID.",
      "allowedPattern": "^(sg-)([0-9a-f]){1,}$"
    },
    "AutomationAssumeRole": {
      "type": "String",
      "description": "(Optional) The ARN of the role that allows Automation to perform the actions on your behalf.",
      "default": "",
      "allowedPattern": "^arn:aws(-cn|-us-gov)?:iam::\\d{12}:role\\/[\\w+=,.@_\\/-]+|^$"
    }
  },
  "mainSteps": [
    {
      "name": "ModifySecurityGroup",
      "action": "aws:executeScript",
      "onFailure": "Abort",
      "isCritical": true,
      "isEnd": true,
      "timeoutSeconds": 600,
      "description": "## ModifySecurityGroup\nAdds a new rule to the security group allowing all traffic (0.0.0.0/0).\n## Inputs\n* SecurityGroupId: The security group ID.\n## Outputs\nThis step has no outputs.\n",
      "inputs": {
        "Runtime": "python3.7",
        "Handler": "modify_security_group_handler",
        "InputPayload": {
          "SecurityGroupId": "${SecurityGroupId}"
        },
        "Script": "import boto3\n\nec2_resource = boto3.resource(\"ec2\")\nec2_client = boto3.client(\"ec2\")\n\ndef modify_security_group_handler(event, context):\n    sg_id = event[\"SecurityGroupId\"]\n    sg_resource = ec2_resource.SecurityGroup(sg_id)\n    successful = True\n    errorMsg = \"\"\n    //more code
      }
  ]
}
