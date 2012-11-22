class WeatherMapPresenter

	@eventTestInstance 		= null
	@localStorageInstance 	= null
	@mapInstance			= null
	@cities 				= null

	constructor: () ->
		do @initialize
		do @run

	initialize: () ->

		@cities = new Cities
		@cities.addListener Cities.CITIES_NEW, @handleNewCityLoaded
		@cities.addListener Cities.CITIES_COMPLETE, @handleAllCitiesLoaded
		@cities.addListener Cities.CITIES_UPDATE, @handleCityWasRefreshed
		@cities.addListener Cities.CITIES_FAILURE, @handleCityRefreshError
		@cities.addListener Cities.CITIES_UNKNOWN, @handleCitiesIsUnknown

		@mapInstance = new Maps 'container'
		@mapInstance.addListener Maps.LOCATION_IS_REMOVED, @handleLocationRemovedFromMap

		@autocompleteInstance = new AutoComplete 'searchbox'
		@autocompleteInstance.addListener AutoComplete.AUTOCOMPLETE_QUERY, @handleAutocompleteAddCity
		@autocompleteInstance.addListener AutoComplete.AUTOCOMPLETE_NOTFOUND, @handleAutocompleteLocationNotFound
		gmapInstance = do @mapInstance.getGoogleMapsInstance
		@autocompleteInstance.bindToGoogleMap gmapInstance

		$('.blue-pill').bind 'click', (e) =>
			do @cities.coldRefreshForecasts

	run: () ->
		do @cities.populate

	handleNewCityLoaded: (params) =>
		@mapInstance.addCityToMap params

	handleAllCitiesLoaded: () =>
		do @cities.mildRefreshForecasts

	handleCityWasRefreshed: (params) =>
		@mapInstance.updateCity params

	handleCityRefreshError: (params) =>
		console.log "Failed updating forecast for "+params.name

	handleCitiesIsUnknown: (params) =>
		console.log "Could not geolocate "+params.name

	handleLocationRemovedFromMap: (cityID) =>
		@cities.removeCity cityID

	handleAutocompleteAddCity: (geolocatedCity) =>
		@cities.generateIdAndAddCity geolocatedCity

	handleAutocompleteLocationNotFound: () =>
		console.log 'Location not found'
