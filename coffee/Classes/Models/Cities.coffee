class Cities extends LocalStorage

	cacheKey			= null
	@cities				= null
	defaults 			= ['Dublin', 'London', 'Paris', 'Barcelona']
	loadCount			= null

	@CITIES_NEW 			= "city_new_added"
	@CITIES_COMPLETE		= "cities_are_loaded"
	@CITIES_UPDATE 			= "city_forecast_update"
	@CITIES_FAILURE	 		= "city_forecast_error"
	@CITIES_UNKNOWN 		= "city_unknown"

	constructor: () ->
		cacheKey 			= 'geoweather'
		@cities 			= []
		loadCount			= 0

	cacheSave: () ->
		data 	= []
		for city in @cities
			fullCityData = do city.getData
			delete fullCityData.forecast
			fullCityData.forecast = {}
			data.push fullCityData
		cacheObject = {'cities': data}
		@store cacheKey, cacheObject

	populate: () ->
		locations = []
		data = @retrieve cacheKey
		if data? and data.cities?
			locations = data.cities
		else
			i=0
			for cityName in defaults
				i++
				locations.push {'id':i, 'name':cityName, 'coords':{}}

		for location in locations
			params =
				id 		: location.id
				name 	: location.name
				coords  : location.coords
			@addCityToStructure params

	addCityToStructure: (params) ->
		city = new City params
		city.addListener City.CITY_LOADED, @handleCityLoaded
		city.addListener City.CITY_UNKNOWN, @handleCityUnknown
		city.addListener City.CITY_FORECAST_SUCCESS, @handleCityForecastSuccess
		city.addListener City.CITY_FORECAST_FAILED, @handleCityForecastFail
		do city.initialize

	generateIdAndAddCity: (geolocatedCity) ->
		if not @cityExists geolocatedCity.name
			cityID = do @getNewCityId
			params =
				id 		: cityID
				name 	: geolocatedCity.name
				coords  : geolocatedCity.coordinates
			@addCityToStructure params

	cityExists: (cityName) ->
		for city in @cities
			if cityName is city.name
				return yes
		return no

	getNewCityId: () ->
		newId = 1
		for city in @cities
			if city.id > newId
				newId = city.id
		newId++
		newId

	findCityIndexForId: (cityID) ->
		i = 0
		for city in @cities
			if city.id is cityID
				return i
			i++
		return -1

	removeCity: (cityID) ->
		realCityID = parseInt(cityID,10);
		@cities = @cities.filter (city) -> city.id isnt realCityID
		do @cacheSave
		loadCount--

	handleCityLoaded: (cityData) =>
		@cities.push cityData
		loadCount++
		data 				= do cityData.getData
		do @cacheSave
		@emitEvent Cities.CITIES_NEW, [data]
		if loadCount >= @cities.length
			@emitEvent Cities.CITIES_COMPLETE, []

	handleCityUnknown: (cityData) =>
		params =
			id 		: cityData.id
			name 	: cityData.location
		@emitEvent Cities.CITIES_UNKNOWN, [params]

	handleCityForecastSuccess: (cityData) =>
		data = do cityData.getData
		cityIndex = @findCityIndexForId cityData.id
		if cityIndex >= 0
			@cities[cityIndex] 		= cityData
			do @cacheSave
			status 					= do cityData.hasValidForecast
			if status
				@emitEvent Cities.CITIES_UPDATE, [data]
			else
				@emitEvent Cities.CITIES_FAILURE, [data]

	handleCityForecastFail: (cityData) =>
		data = do cityData.getData
		cityIndex = @findCityIndexForId cityData.id
		if cityIndex >= 0
			@emitEvent Cities.CITIES_FAILURE, [data]

	coldRefreshForecasts: ->
		for city in @cities
			do city.refreshForecast

	mildRefreshForecasts: ->
		for city in @cities
			validForecast = do city.hasValidForecast
			if not validForecast
				do city.refreshForecast

	showData: () ->
		console.log @