variable "hero_thousand_faces" {
  description = "map"
  type = map(string)
  default = {
    "neo" = "hero"
    "morpheus" = "mentor"
    "trinity" = "lover"
  }
}

output "bios" {
  value = [for name, role in var.hero_thousand_faces : "${name} is the ${role}." ]
}