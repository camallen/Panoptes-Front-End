React = require 'react'
BoundResourceMixin = require '../../lib/bound-resource-mixin'
handleInputChange = require '../../lib/handle-input-change'
ChangeListener = require '../../components/change-listener'
auth = require '../../api/auth'
PromiseRenderer = require '../../components/promise-renderer'
ImageSelector = require '../../components/image-selector'
apiClient = require '../../api/client'
putFile = require '../../lib/put-file'

MAX_AVATAR_SIZE = 65536
MAX_HEADER_SIZE = 256000
MIN_PASSWORD_LENGTH = 8

ChangePasswordForm = React.createClass
  displayName: 'ChangePasswordForm'

  getDefaultProps: ->
    user: {}

  getInitialState: ->
    old: ''
    new: ''
    confirmation: ''
    inProgress: false
    success: false
    error: null

  render: ->
    <form ref="form" onSubmit={@handleSubmit}>
      <p>
        <strong>Change your password</strong>
      </p>

      <table className="standard-table">
        <tbody>
          <tr>
            <td>Current password</td>
            <td><input type="password" className="standard-input" size="20" onChange={(e) => @setState old: e.target.value} /></td>
          </tr>
          <tr>
            <td>New password</td>
            <td>
              <input type="password" className="standard-input" size="20" onChange={(e) => @setState new: e.target.value} />
              {if @state.new.length isnt 0 and @tooShort()
                <small className="form-help error">That’s too short</small>}
            </td>
          </tr>
          <tr>
            <td>Confirm new password</td>
            <td>
              <input type="password" className="standard-input" size="20" onChange={(e) => @setState confirmation: e.target.value} />
              {if @state.confirmation.length >= @state.new.length - 1 and @doesntMatch()
                <small className="form-help error">These don’t match</small>}
            </td>
          </tr>
        </tbody>
      </table>

      <p>
        <button type="submit" className="standard-button" disabled={not @state.old or not @state.new or @tooShort() or @doesntMatch() or @state.inProgress}>Change</button>{' '}

        {if @state.inProgress
          <i className="fa fa-spinner fa-spin form-help"></i>
        else if @state.success
          <i className="fa fa-check-circle form-help success"></i>
        else if @state.error
          <small className="form-help error">{@state.error.toString()}</small>}
      </p>
    </form>

  tooShort: ->
    @state.new.length < MIN_PASSWORD_LENGTH

  doesntMatch: ->
    @state.new isnt @state.confirmation

  handleSubmit: (e) ->
    e.preventDefault()

    current = @state.old
    replacement = @state.new

    @setState
      inProgress: true
      success: false
      error: null

    auth.changePassword {current, replacement}
      .then =>
        @setState success: true
        @refs.form.getDOMNode().reset()
      .catch (error) =>
        @setState {error}
      .then =>
        @setState inProgress: false

UserSettingsPage = React.createClass
  displayName: 'UserSettingsPage'

  mixins: [BoundResourceMixin]

  boundResource: 'user'

  getDefaultProps: ->
    user: {}

  getInitialState: ->
    avatarError: null
    headerError: null

  render: ->
    @getAvatarSrc ?= @props.user.get 'avatar'
      .then ([avatar]) ->
        avatar.src
      .catch ->
        ''

    @getHeaderSrc ?= @props.user.get 'header'
      .then (header) ->
        header.src
      .catch ->
        ''

    <div>
      <div className="columns-container">
        <div className="content-container">
          Avatar<br />
          <PromiseRenderer promise={@getAvatarSrc} then={(avatarSrc) =>
            placeholder = <div className="form-help content-container">Drop an image here</div>
            <ImageSelector maxSize={MAX_AVATAR_SIZE} ratio={1} defaultValue={avatarSrc} placeholder={placeholder} onChange={@handleMediaChange.bind(this, 'avatar')} />
          } />
          {if @state.avatarError
            <div className="form-help error">{@state.avatarError.toString()}</div>}
        </div>

        <div className="content-container">
          Profile Header<br />
          <PromiseRenderer promise={@getHeaderSrc} then={(headerSrc) =>
            placeholder = <div className="form-help content-container">Drop an image here</div>
            <ImageSelector maxSize={MAX_HEADER_SIZE} defaultValue={headerSrc} placeholder={placeholder} onChange={@handleMediaChange.bind(this, 'header')} />
          } />
          {if @state.headerError
            <div className="form-help error">{@state.headerError.toString()}</div>}
        </div>

        <hr />

        <div className="content-container column">
          <table className="standard-table full">
            <tr>
              <th>Credited name</th>
              <td>
                <input type="text" className="standard-input full" name="credited_name" value={@props.user.credited_name} onChange={@handleChange} />
                <div className="form-help">Public; we’ll use this to give acknowledgement in papers, on posters, etc.</div>
              </td>
            </tr>
          </table>

          <p>
            <label>
              <input type="checkbox" name="global_email_communication" checked={@props.user.global_email_communication} onChange={@handleChange} />{' '}
              Get general Zooniverse email updates
            </label>
          </p>

          <p>
            <button type="button" className="standard-button" disabled={@state.saveInProgress or not @props.user.hasUnsavedChanges()} onClick={@saveResource}>Save profile</button>{' '}
            {@renderSaveStatus()}
          </p>
        </div>
      </div>

      <hr />

      <div className="content-container">
        <p><strong>Project email preferences</strong></p>
        <table>
          <thead>
            <tr>
              <th><i className="fa fa-envelope-o fa-fw"></i></th>
              <th>Project</th>
            </tr>
          </thead>
          <PromiseRenderer promise={@props.user.get 'project_preferences'} pending={=> <tbody></tbody>} then={(projectPreferences) =>
            <tbody>
              {for projectPreference in projectPreferences then do (projectPreference) =>
                <PromiseRenderer key={projectPreference.id} promise={projectPreference.get 'project'} then={(project) =>
                  <ChangeListener target={projectPreference} handler={=>
                    <tr>
                      <td><input type="checkbox" name="email_communication" checked={projectPreference.email_communication} onChange={@handleProjectEmailChange.bind this, projectPreference} /></td>
                      <td>{project.display_name}</td>
                    </tr>
                  } />
                } />}
            </tbody>
          } />
        </table>
      </div>

      <hr />

      <div className="content-container">
        <ChangePasswordForm {...@props} />
      </div>
    </div>

  handleMediaChange: (type, file) ->
    errorProp = "#{type}Error"

    newState = {}
    newState[errorProp] = null
    @setState newState, -> console.log 'state', @state

    apiClient.post @props.user._getURL(type), media: content_type: file.type
      .then ([resource]) =>
        putFile resource.src, file
      .then =>
        @props.user.uncacheLink type
        @["#{type}SrcGet"] = null # Uncache the local request so that rerendering makes it again.
        @props.user.emit 'change'
      .catch (error) =>
        newState = {}
        newState[errorProp] = error
        @setState newState

  handleProjectEmailChange: (projectPreference, args...) ->
    handleInputChange.apply projectPreference, args
    projectPreference.save()

module.exports = React.createClass
  displayName: 'UserSettingsPageWrapper'

  render: ->
    <ChangeListener target={auth} handler={=>
      <PromiseRenderer promise={auth.checkCurrent()} then={(user) =>
        if user?
          <UserSettingsPage user={user} />
        else
          <div className="content-container">
            <p>You’re not signed in.</p>
          </div>
      } />
    } />
