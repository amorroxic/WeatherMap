class Cities extends LocalStorage

	cacheKey			= null
	@autoIncrement		= null
	@locations			= null
	@cityDescriptors 	= null
	defaults 			= ['Dublin', 'London', 'Paris', 'Barcelona']
	loadCount			= null

	@CITIES_NEW 			= "city_new_added"
	@CITIES_COMPLETE		= "cities_are_loaded"
	@CITIES_UPDATE 			= "city_forecast_update"
	@CITIES_FAILURE	 		= "city_forecast_error"
	@CITIES_UNKNOWN 		= "city_unknown"

	constructor: () ->
		cacheKey 			= 'cities'
		@locations			= {}
		@cityDescriptors 	= []
		@autoIncrement		= 0
		loadCount			= 0

	cacheSave: () ->
		cacheObject = {'autoIncrement':@autoIncrement, 'cities': @cityDescriptors}
		@store cacheKey, cacheObject

	populate: () ->

		data = @retrieve cacheKey
		if data? and data.autoIncrement? and data.cities?
			@autoIncrement = data.autoIncrement
			@cityDescriptors = data.cities
		else
			i = 0
			for cityName in defaults
				i++
				@cityDescriptors.push {'id':i, 'name':cityName}
			@autoIncrement = i+1
			do @cacheSave

		for cityDescriptor in @cityDescriptors
			params =
				id : cityDescriptor.id
				name : cityDescriptor.name
			@addCityToStructure params

	addCityToStructure: (params) ->
		city = new City params
		city.addListener City.CITY_LOADED, @handleCityLoaded
		city.addListener City.CITY_UNKNOWN, @handleCityUnknown
		city.addListener City.CITY_FORECAST_SUCCESS, @handleCityForecastSuccess
		city.addListener City.CITY_FORECAST_FAILED, @handleCityForecastFail
		do city.populate

	generateIdAndAddCity: (cityName) ->
		if not @cityExists cityName
			cityID = @autoIncrement
			@cityDescriptors.push {'id':cityID, 'name':cityName}
			@autoIncrement++
			do @cacheSave
			params =
				id : cityID
				name : cityName
			@addCityToStructure params

	cityExists: (cityName) ->
		for descriptor in @cityDescriptors
			if cityName is descriptor.name
				return yes
		return no

	removeCity: (cityID) ->
		realCityID = parseInt(cityID,10);
		@cityDescriptors = @cityDescriptors.filter (descriptor) -> descriptor.id isnt realCityID
		if @locations[cityID]
			do @locations[cityID].destroy
			delete @locations[cityID]
		do @cacheSave
		loadCount--

	handleCityLoaded: (cityData) =>
		i = 0
		for descriptor in @cityDescriptors
			@cityDescriptors[i].name = cityData.location if cityData.id is descriptor.id
			i++
		do @cacheSave
		@locations[cityData.id] = cityData
		params =
			id : cityData.id
			name : cityData.location
			coords : cityData.coordinates
			overview : do cityData.getForecastOverview
			forecast : cityData.forecast
		@emitEvent Cities.CITIES_NEW, [params]
		loadCount++
		if loadCount >= @cityDescriptors.length
			@emitEvent Cities.CITIES_COMPLETE, []

	handleCityUnknown: (cityData) =>
		params =
			id : cityData.id
			name : cityData.location
		@emitEvent Cities.CITIES_UNKNOWN, [params]

	handleCityForecastSuccess: (cityData) =>
		params =
			id : cityData.id
			name : cityData.location
			coords : cityData.coordinates
			overview : do cityData.getForecastOverview
			forecast : cityData.forecast
		status = do cityData.hasValidForecast
		if status
			@emitEvent Cities.CITIES_UPDATE, [params]
		else
			@emitEvent Cities.CITIES_FAILURE, [params]

	handleCityForecastFail: (cityData) =>
		params =
			id : cityData.id
			name : cityData.location
			coords : cityData.coordinates
			overview : do cityData.getForecastOverview
		@emitEvent Cities.CITIES_FAILURE, [params]

	coldRefreshForecasts: ->
		for cityID of @locations
			city = @locations[cityID]
			do city.refreshForecast

	mildRefreshForecasts: ->
		for cityID of @locations
			city = @locations[cityID]
			validForecast = do city.hasValidForecast
			if not validForecast
				do city.refreshForecast

	showData: () ->
		console.log @