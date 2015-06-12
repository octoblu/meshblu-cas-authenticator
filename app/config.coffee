passport = require 'passport'
CitrixStrategy = require('passport-citrix-auth-service').Strategy
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
debug = require('debug')('meshblu-citrix-authenticator:config')

citrixOauthConfig =
  authorizationURL: 'https://authentication.citrixonline.com/oauth/authorize'
  tokenURL: 'https://authentication.citrixonline.com/oauth/token'
  clientID: 'd79e5c4e-d79f-49eb-8263-b3888e940443' #process.env.CITRIX_CLIENT_ID
  clientSecret: '3cAfP6qHOzJX0exDB+aUmA==' #process.env.CITRIX_CLIENT_SECRET
  callbackURL: 'http://localhost:8008/oauthcallback' #process.env.CITRIX_CALLBACK_URL
  passReqToCallback: false

class CitrixConfig
  constructor: (@meshbludb, @meshbluJSON) ->

  register: =>
    passport.use new CitrixStrategy citrixOauthConfig, @onAuthentication

  onAuthentication: (accessToken, refreshToken, profile, done) =>
    profileId = profile.id
    fakeSecret = 'citrix-authenticator'
    authenticatorUuid = @meshbluJSON.uuid
    authenticatorName = @meshbluJSON.name
    deviceModel = new DeviceAuthenticator authenticatorUuid, authenticatorName, meshbludb: @meshbludb
    query = {}
    query[authenticatorUuid + '.id'] = profileId
    device =
      name: 'meshblu-citrix-authenticator'
      type: 'octoblu:user'

    getDeviceToken = (uuid) =>
      @meshbludb.generateAndStoreToken uuid, (error, device) =>
        device.id = profileId
        done null, device

    deviceCreateCallback = (error, createdDevice) =>
      return done error if error?
      getDeviceToken createdDevice?.uuid

    deviceFindCallback = (error, foundDevice) =>
      return getDeviceToken foundDevice.uuid if foundDevice?
      deviceModel.create query, device, profileId, fakeSecret, deviceCreateCallback

    deviceModel.findVerified query, fakeSecret, deviceFindCallback

module.exports = CitrixConfig
