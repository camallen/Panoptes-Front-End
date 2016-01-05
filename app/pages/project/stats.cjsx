React = require 'react'
ChartistGraph = require 'react-chartist'
moment = require 'moment'
qs = require 'qs'
PromiseRenderer = require '../../components/promise-renderer'
config = require '../../api/config'
{Model, makeHTTPRequest} = require 'json-api-client'

CHARTIST_CSS = '//cdn.jsdelivr.net/chartist.js/latest/chartist.min.css'

MS_PER_HOUR = 3600000
NOW = Date.now()

Graph = React.createClass
  getDefaultProps: ->
    data: []
    options: {}

  componentDidMount: ->
    # Hack day!
    unless document.querySelector "[href='#{CHARTIST_CSS}']"
      link = document.createElement 'link'
      link.rel = 'stylesheet'
      link.href = CHARTIST_CSS
      document.head.appendChild link

  formatLabel:
    hourly: (date) -> moment(date).format 'h'

  render: ->
    data =
      labels: []
      series: [[]]

    @props.data.forEach ({label, value}) =>
      data.labels.push @formatLabel[@props.by]?(label) ? label
      data.series[0].push value

    <div style={background: 'white'}>
      <ChartistGraph type="Bar" data={data} options={@props.options} />
    </div>

ProjectStatsPage = React.createClass
  getDefaultProps: ->
    totalClassifications: 0
    requiredClassifications: 0
    totalVolunteers: 2
    currentVolunteers: 46
    classificationsBy: 'hour'
    volunteersBy: 'hour'

  classification_count: (period) ->
    stats_url = "#{config.statHost}/counts/classification/#{period}/?project_id=#{@props.projectId}"
    # console.log stats_url
    makeHTTPRequest 'GET', stats_url
      .then (response) =>
        results = JSON.parse response.responseText
        bucket_data = results["events_over_time"]["buckets"]
        data = bucket_data.map (stat_object) =>
          label: stat_object.key_as_string
          value: stat_object.doc_count
        # console?.log data
      .catch (response) ->
        console?.error 'Failed to get the stats'

  volunteer_count: (period) ->
    []

  render: ->
    <div className="project-stats-page">
      <div className="project-stats-dashboard">
        <div className="major">
          {@props.totalClassifications}<br />
          Classifications
        </div>
        <div>
          {@props.totalVolunteers}<br />
          Volunteers
        </div>

        <div className="major">
          <meter value={@props.totalClassifications} max={@props.requiredClassifications} /><br />
          {Math.floor 100 * (@props.totalClassifications / @props.requiredClassifications)}% complete
        </div>
        <div>
          {@props.currentVolunteers}<br />
          Online now
        </div>
      </div>

      <div>
        Classifications per{' '}
        <select value={@props.classificationsBy} onChange={@handleGraphChange.bind this, 'classifications'}>
          <option value="hour">hour</option>
          <option value="day">day</option>
          <option value="week">week</option>
          <option value="month">month</option>
        </select><br />
        <PromiseRenderer promise={@classification_count(@props.classificationsBy)}>{(classificationData) =>
          <Graph data={classificationData} />
        }</PromiseRenderer>
      </div>

      <div>
        Volunteers per{' '}
        <select value={@props.volunteersBy} onChange={@handleGraphChange.bind this, 'volunteers'}>
          <option value="hour">hour</option>
          <option value="day">day</option>
          <option value="week">week</option>
          <option value="month">month</option>
        </select><br />
        <Graph data={@volunteer_count(@props.volunteersBy)} />
      </div>
    </div>

  handleGraphChange: (which, e) ->
    query = qs.parse location.search.slice 1
    query[which] = e.target.value
    location.search = qs.stringify query

ProjectStatsPageController = React.createClass
  render: ->
    # console.log @props
    queryProps =
      # classificationsBy: @props.query.classifications
      # volunteersBy: @props.query.volunteers
      projectId: @props.project.id

    <ProjectStatsPage {...queryProps} />

module.exports = ProjectStatsPageController
