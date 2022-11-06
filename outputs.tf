output "message_forwarding_function_url" {
  value       = "https://${twilio_serverless_environment.forwarding.domain_name}${twilio_serverless_function.sms.path}"
  description = "URL of the function that forwards messages. Configure your phone number to POST to this URL for messages."
}

output "voice_forwarding_function_url" {
  value       = "https://${twilio_serverless_environment.forwarding.domain_name}${twilio_serverless_function.voice.path}"
  description = "URL of the function that forwards voice. Configure your phone number to POST to this URL for voice."
}
