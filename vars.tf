variable "area_code" {
  type     = string
  nullable = false
}

variable "forward_to" {
  type        = string
  description = "Phone number to forward SMS and voice to."
  nullable    = false

  validation {
    condition     = can(regex("^\\+?[1-9]\\d{1,14}$", var.forward_to))
    error_message = "Phone number must comply with E.164."
  }
}

