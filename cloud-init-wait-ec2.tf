resource "aws_ssm_document" "cloud_init_wait" {
  name = "cloud-init-wait"
  document_type = "Command"
  document_format = "YAML"
  content = <<-DOC
    schemaVersion: '2.2'
    description: Wait for cloud init to finish
    mainSteps:
    - action: aws:runShellScript
      name: StopOnLinux
      precondition:
        StringEquals:
        - platformType
        - Linux
      inputs:
        runCommand:
        - cloud-init status --wait
    DOC
}

resource "aws_instance" "example" {
  ami           = "my-ami"
  instance_type = "t3.micro"
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOF
    set -Ee -o pipefail
    export AWS_DEFAULT_REGION=${data.aws_region.current.name}
    command_id=$(aws ssm send-command --document-name ${aws_ssm_document.cloud_init_wait.arn} --instance-ids ${self.id} --output text --query "Command.CommandId")
    if ! aws ssm wait command-executed --command-id $command_id --instance-id ${self.id}; then
      echo "Failed to start services on instance ${self.id}!";
      echo "stdout:";
      aws ssm get-command-invocation --command-id $command_id --instance-id ${self.id} --query StandardOutputContent;
      echo "stderr:";
      aws ssm get-command-invocation --command-id $command_id --instance-id ${self.id} --query StandardErrorContent;
      exit 1;
    fi;
    echo "Services started successfully on the new instance with id ${self.id}!"
    EOF
  }
}
