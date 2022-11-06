terraform {
  required_providers {
    twilio = {
      source  = "RJPearson94/twilio"
      version = "0.19.0"
    }
    twilionew = {
      source  = "twilio/twilio"
      version = "0.18.8"
    }
  }
}

resource "twilio_serverless_services_v1" "forwarding" {
  provider      = twilionew
  unique_name   = "forwarding"
  friendly_name = "forwarding"
  ui_editable   = false
}

resource "twilio_serverless_environment" "forwarding" {
  unique_name = "forwarding-todo-replace-this-with-unique-1121"
  service_sid = twilio_serverless_services_v1.forwarding.sid
}

resource "twilio_serverless_deployment" "forwarding" {
  service_sid     = twilio_serverless_services_v1.forwarding.sid
  environment_sid = twilio_serverless_environment.forwarding.sid
  build_sid       = twilio_serverless_build.forwarding.sid

  lifecycle {
    create_before_destroy = true
  }
}

resource "twilio_serverless_build" "forwarding" {
  provider    = twilio
  service_sid = twilio_serverless_services_v1.forwarding.sid
  runtime     = "node14"

  function_version {
    sid = twilio_serverless_function.sms.latest_version_sid
  }

  function_version {
    sid = twilio_serverless_function.voice.latest_version_sid
  }

  dependencies = {
    "twilio"                  = "3.83.1"
    "@twilio/runtime-handler" = "1.2.5"
  }

  polling {
    enabled = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "twilio_serverless_function" "sms" {
  service_sid   = twilio_serverless_services_v1.forwarding.sid
  friendly_name = "smsForwarding"

  # https://www.twilio.com/blog/sms-forwarding-and-responding-using-twilio-and-javascript
  content           = <<EOF
exports.handler = function(context, event, callback) {
    let twiml = new Twilio.twiml.MessagingResponse();
    if (event.From === context.DESTINATION) {
        const separatorPosition = event.Body.indexOf(':');
        if (separatorPosition < 1) {
            twiml.message('You need to specify a recipient number and a ":" before the message.');
        } else {
            const recipientNumber = event.Body.substr(0, separatorPosition).trim();
            const messageBody = event.Body.substr(separatorPosition + 1).trim();
            twiml.message({ to: recipientNumber }, messageBody);
        }
    } else {
        twiml.message({ to: context.DESTINATION }, `$${event.From}: $${event.Body}`);
    }
    callback(null, twiml);
};
EOF
  content_type      = "application/javascript"
  content_file_name = "sms.js"
  path              = "/sms"
  visibility        = "protected"
}

resource "twilio_serverless_function" "voice" {
  service_sid   = twilio_serverless_services_v1.forwarding.sid
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

resource "twilio_serverless_services_environments_variables_v1" "destination" {
  provider        = twilionew
  service_sid     = twilio_serverless_services_v1.forwarding.sid
  environment_sid = twilio_serverless_environment.forwarding.sid
  key             = "DESTINATION"
  value           = var.forward_to
}
