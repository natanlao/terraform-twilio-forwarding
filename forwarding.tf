# TODO: cite twilio examples
data "twilio_account_details" "account_details" {}

resource "twilio_phone_number" "phone_number" {
  account_sid   = data.twilio_account_details.account_details.sid
  friendly_name = "test"
  area_code     = var.area_code

  messaging {
    url    = "https://${twilio_serverless_environment.forwarding.domain_name}${twilio_serverless_function.sms.path}"
    method = "POST"
  }
}

resource "twilio_serverless_service" "forwarding" {
  unique_name   = "forwarding"
  friendly_name = "forwarding"
  ui_editable   = false
}

resource "twilio_serverless_environment" "forwarding" {
  unique_name = "stupid-foo-name"
  service_sid = twilio_serverless_service.forwarding.sid
}

resource "twilio_serverless_deployment" "forwarding" {
  service_sid     = twilio_serverless_service.forwarding.sid
  environment_sid = twilio_serverless_environment.forwarding.sid
  build_sid       = twilio_serverless_build.forwarding.sid

  lifecycle {
    create_before_destroy = true
  }
}
resource "twilio_serverless_build" "forwarding" {
  service_sid = twilio_serverless_service.forwarding.sid
  runtime     = "node12"

  function_version {
    sid = twilio_serverless_function.sms.latest_version_sid
  }

  function_version {
    sid = twilio_serverless_function.voice.latest_version_sid
  }

  # TODO: prune dependencies
  dependencies = {
    "twilio"                  = "3.6.3"
    "fs"                      = "0.0.1-security"
    "lodash"                  = "4.17.11"
    "util"                    = "0.11.0"
    "xmldom"                  = "0.1.27"
    "@twilio/runtime-handler" = "1.0.1"
  }

  polling {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "twilio_serverless_function" "sms" {
  service_sid   = twilio_serverless_service.forwarding.sid
  friendly_name = "smsForwarding"

  content           = <<EOF
exports.handler = function(context, event, callback) {
  let twiml = new Twilio.twiml.MessagingResponse();
  twiml.message(`$${event.From}: $${event.Body}`, {
    to: context.DESTINATION
  });
  callback(null, twiml);
};
EOF
  content_type      = "application/javascript"
  content_file_name = "sms.js"
  path              = "/sms"
  visibility        = "protected"
}

resource "twilio_serverless_function" "voice" {
  service_sid   = twilio_serverless_service.forwarding.sid
  friendly_name = "callForwarding"

  content           = <<EOF
exports.handler = function (context, event, callback) {
  const twiml = new Twilio.twiml.VoiceResponse();
  twiml.dial(context.DESTINATION);
  callback(null, twiml);
};
EOF
  content_type      = "application/javascript"
  content_file_name = "call.js"
  path              = "/call"
  visibility        = "protected"
}

resource "twilio_serverless_variable" "destination" {
  service_sid     = twilio_serverless_service.forwarding.sid
  environment_sid = twilio_serverless_environment.forwarding.sid
  key             = "DESTINATION"
  value           = var.forward_to
}