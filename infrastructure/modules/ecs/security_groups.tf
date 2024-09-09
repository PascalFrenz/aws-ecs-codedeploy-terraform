# ------------------------------ Security Group config for the load balancer ------------------------------

resource "aws_security_group_rule" "lb_egress_http" {
  type                     = "egress"
  from_port                = var.example_service_port
  to_port                  = var.example_service_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.service.id
  description              = "Allow http traffic from the load balancer to the service"
  security_group_id        = var.alb_security_group_id
}

# ------------------------------ Security Group config for the service ------------------------------

resource "aws_security_group" "service" {
  name                   = var.cluster_name
  description            = "Allow traffic towards the service"
  revoke_rules_on_delete = false

  tags = {}
}

resource "aws_security_group_rule" "service_ingress_http" {
  type                     = "ingress"
  from_port                = var.example_service_port
  to_port                  = var.example_service_port
  protocol                 = "tcp"
  description              = "Allow http traffic from the load balancer"
  source_security_group_id = var.alb_security_group_id
  security_group_id        = aws_security_group.service.id
}

resource "aws_security_group_rule" "service_egress_https" {
  type              = "egress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow https traffic from the service to the internet"
  security_group_id = aws_security_group.service.id
}
