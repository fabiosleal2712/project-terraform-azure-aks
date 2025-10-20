resource "aws_instance" "web" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = element(var.subnet_ids, count.index)
  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "web-instance-${count.index}"
  }
}

resource "aws_launch_template" "example" {
  name                   = "example-launch-template"
  image_id               = var.ami_id        // Usar a variável ami_id
  instance_type          = var.instance_type // Usar a variável instance_type
  vpc_security_group_ids = [var.security_group_id]

  lifecycle {
    create_before_destroy = true
  }

  provisioner "local-exec" {
    command = "echo Launch template created"
  }
}

resource "aws_autoscaling_group" "example" {
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = var.subnet_ids
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "example-asg"
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.example.name
}