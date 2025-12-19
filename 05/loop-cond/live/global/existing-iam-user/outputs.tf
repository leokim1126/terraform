output "all_ids" {
  value = aws_iam_user.createuser[*]
}

output "upper_user_names" {
  value = [for name in var.user_names : upper(name) if length(name) < 3]
}