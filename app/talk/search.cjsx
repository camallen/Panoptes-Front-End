React = require 'react'
{ Navigation } = require '@edpaget/react-router'
talkClient = require '../api/talk'
Paginator = require './lib/paginator'
TalkSearchResult = require './search-result'
resourceCount = require './lib/resource-count'
Loading = require '../components/loading-indicator'

TALK_SEARCH_ERROR_MESSAGE = 'There was an error with your search. Please try again.'
VALID_SEARCH_PARAMS = ['page', 'page_size', 'query', 'types', 'section']

filterObjectKeys = (object, validKeys) ->
  newObject = {}

  for key, value of object
    if validKeys.indexOf(key) > -1
      newObject[key] = value

  return newObject

module.exports = React.createClass
  displayName: 'TalkSearch'
  mixins: [Navigation]

  getInitialState: ->
    errorThrown: false
    isLoading: true
    results: []
    resultsMeta: {}

  componentDidMount: ->
    @runSearchQuery filterObjectKeys @props.query, VALID_SEARCH_PARAMS

  componentWillReceiveProps: (nextProps) ->
    @runSearchQuery filterObjectKeys nextProps.query, VALID_SEARCH_PARAMS

  runSearchQuery: (params) ->
    @setState
      errorThrown: false
      isLoading: true
      results: []

    defaultParams =
      section: @props.section
      types: ['comments']
      page: 1
      page_size: 10

    paramsToUse = Object.assign defaultParams, params

    talkClient.type('searches').get(paramsToUse).then (searches) =>
      @setState
        results: searches
        resultsMeta: searches[0]?.getMeta('searches')
    .catch (e) =>
      @setState errorThrown: true
    .then =>
      @setState isLoading: false

  onPageChange: (page) ->
    @goToPage page

  goToPage: (n) ->
    nextQuery = Object.assign @props.query, {page: n}

    @transitionTo location.pathname, @props.params, nextQuery

  render: ->
    numberOfResults = @state.results.length

    <div className="talk-search">
      {if @state.isLoading
        <Loading />}

      {if @state.errorThrown
        <p className="form-help error">{TALK_SEARCH_ERROR_MESSAGE}</p>}

      {if !@state.isLoading && numberOfResults == 0 && !@state.errorThrown
        <p>No results found.</p>}

      {if !@state.isLoading && numberOfResults > 0
        <div className="talk-search-container">
          <div className="talk-search-counts">
            Your search returned {resourceCount @state.resultsMeta.count, 'results'}.
          </div>

          <div className="talk-search-results">
            {@state.results.map (result, i) =>
              <TalkSearchResult {...@props} data={result} key={i} />}
            <Paginator page={+@state.resultsMeta.page} onPageChange={@onPageChange} pageCount={@state.resultsMeta.page_count} />
          </div>
        </div>}
    </div>
