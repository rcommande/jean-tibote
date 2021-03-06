type challenge = string

type authorization = {userId: string}
type authorizations = array<authorization>

type botProfile = {
  id: string,
  name: string,
}

type event = {
  text: string,
  ts: option<string>,
  user: string,
  team: string,
  channel: string,
  botId: option<string>,
  threadTs: option<string>,
  _type: string,
  channelType: option<string>,
  botProfile: option<botProfile>,
}

type eventPayload = {
  teamId: string,
  apiAppId: string,
  _type: string,
  eventId: string,
  eventTime: int,
  isExtSharedChannel: bool,
  eventContext: string,
  event: event,
  authorizations: authorizations,
}

type requests =
  | Challenge(string)
  | Event(eventPayload)
  | Invalid
  | Unreadable(Js.Json.t)

let authorizationsDecoder = json => {
  open Json.Decode
  {
    userId: field("user_id", string, json),
  }
}

let botProfileDecoder = json => {
  open Json.Decode
  {
    id: field("id", string, json),
    name: field("name", string, json),
  }
}

let eventDecoder = json => {
  open Json.Decode
  {
    text: field("text", string, json),
    ts: field("ts", optional(string), json),
    user: field("user", string, json),
    team: field("team", string, json),
    channel: field("channel", string, json),
    botId: optional(field("bot_id", string), json),
    threadTs: optional(field("thread_ts", string), json),
    _type: field("type", string, json),
    channelType: optional(field("channel_type", string), json),
    botProfile: optional(field("bot_profile", botProfileDecoder), json),
  }
}

let eventPayloadDecoder = json => {
  open Json.Decode
  {
    teamId: field("team_id", string, json),
    apiAppId: field("api_app_id", string, json),
    _type: field("type", string, json),
    eventId: field("event_id", string, json),
    eventTime: field("event_time", int, json),
    isExtSharedChannel: field("is_ext_shared_channel", bool, json),
    eventContext: field("event_context", string, json),
    event: field("event", eventDecoder, json),
    authorizations: field("authorizations", array(authorizationsDecoder), json),
  }
}

let isValidPayload = json => {
  open Json.Decode
  switch field("token", string, json) {
  | token => token === Settings.slackVerificationToken
  | exception DecodeError(_) => false
  }
}

let getPayload = json => {
  open Json.Decode
  isValidPayload(json)
    ? switch field("challenge", string, json) {
      | value => Challenge(value)
      | exception DecodeError(_) =>
        switch eventPayloadDecoder(json) {
        | value => Event(value)
        | exception DecodeError(_) => Unreadable(json)
        }
      }
    : Invalid
}
