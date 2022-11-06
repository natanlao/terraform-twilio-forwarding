# terraform-twilio-forwarding

Twilio functions that forward SMS and calls to a given phone number.

For example:

```terraform
terraform {
  required_providers {
    twilio = {
      source  = "RJPearson94/twilio"
      version = "0.19.0"
    }
  }
}

provider "twilio" {}

module "forwarding" {
  source = "git@github.com:natanlao/terraform-twilio-forwarding.git"
  forward_to = ...
}

data "twilio_account_details" "account_details" {}

resource "twilio_phone_number" "phone_number" {
  account_sid   = data.twilio_account_details.account_details.sid
  friendly_name = "forwarded"
  phone_number = ...

  messaging {
    url = module.forwarding.message_forwarding_function_url
    method = "POST"
  }

  voice {
    url = module.forwarding.voice_forwarding_function_url
    method = "POST"
  }
}

```

```console
export TWILIO_ACCOUNT_SID=...
export TWILIO_AUTH_TOKEN=...
terraform apply
```

Then SMS and calls will ring the `forward_to` number specified. You can also
send text messages from this number by sending a message to your
`twilio_phone_number.phone_number` prefixed with another number, e.g.
`+15555555555: Send a test message to +1 (555) 555 5555`.


## TODOs

* Add some kind of versioning
* Add tests
* This code uses Twilio example code; cite repositories and check licensing
* Finish transitioning to the official Twilio provider. (It's not fully stable
  though, so it may take some time.)

