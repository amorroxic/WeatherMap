class City extends LocalStorage

	@id 				= null
	@location 			= null
	@coordinates		= null
	@forecast 			= null
	@isGeolocated 		= null
	@hasForecast 		= null
	@weatherAPI 		= null

	@CITY_LOADED 	 		= "city_cache_loaded"
	@CITY_UNKNOWN 			= "city_is_unknown"
	@CITY_FORECAST_FAILED 	= "city_forecast_failed"
	@CITY_FORECAST_SUCCESS 	= "city_forecast_success"

	constructor: (params) ->
		@id 				= params.id
		@location			= params.name
		@forecast 			= {}
		@coordinates		= null
		@hasForecast 		= no
		@isGeolocated 		= no
		@weatherAPI 		= "http://free.worldweatheronline.com/feed/weather.ashx"


	populate: () ->
		isInitialized 		= do @cacheLoad
		if isInitialized
			@emitEvent City.CITY_LOADED, [@]

	cacheLoad: () ->
		loaded = no
		if @id?
			data = @retrieve @id
			if data?
				@isGeolocated = @populateCoordinates data
				if not @isGeolocated
					do @geolocateMe
				else
					loaded = yes
					if data.forecast? and data.forecast.current?
						@forecast = data.forecast
						validForecast = do @hasValidForecast
						if validForecast
							@hasForecast = yes
			else
				do @geolocateMe

		loaded

	cacheSave: () ->
		saved = no
		if @id?
			@store @id, @
			saved = yes
		saved

	destroy: () ->
		@remove @id
		@isGeolocated = no
		@hasForecast = no
		@forecast = {}

	populateCoordinates: (data) ->
		foundCoordinates = no
		if data.coordinates?
			@location = data.location
			@coordinates = {}
			@coordinates.latitude = data.coordinates.latitude
			@coordinates.longitude = data.coordinates.longitude
			foundCoordinates = yes
		foundCoordinates

	geolocateMe: () ->
		@forecast = {}
		@hasForecast = no
		coder = new Geocoder @location
		coder.addListener Geocoder.SUCCESS, @geolocationSuccess
		coder.addListener Geocoder.FAILURE, @geolocationFailure
		do coder.perform

	geolocationSuccess: (data) =>
		@location = data.location
		@isGeolocated = @populateCoordinates data
		do @cacheSave
		@emitEvent City.CITY_LOADED, [@]

	geolocationFailure: (text) =>
		@emitEvent City.CITY_UNKNOWN, [@]

	refreshForecast: () ->
		console.log "Refreshing forecast for: "+@location
		request = new Ajax @weatherAPI
		request.addListener Ajax.LOAD_SUCCESS, @forecastSuccess
		request.addListener Ajax.LOAD_FAILED, @forecastFailure
		params = {
			'q'				: @location,
			'format'		: 'json',
			'num_of_days'	: 2,
			'key'			: 'bbfbbfb160072942122708'
		}
		request.perform params

	forecastSuccess: (result) =>
		if not result.data.error?
			@populateForecast result.data
			@hasForecast = yes
			do @cacheSave
			@emitEvent City.CITY_FORECAST_SUCCESS, [@]
		else
			@emitEvent City.CITY_FORECAST_FAILED, [@]

	forecastFailure: (data) =>
		@emitEvent City.CITY_FORECAST_FAILED, [@]

	populateForecast: (data) ->

		currentForecast = {
			'date'			: data.weather[0].date
			'time'			: data.current_condition[0].observation_time,
			'precip_mm'		: data.current_condition[0].precipMM,
			'temp'			: {
								'f'	:	data.current_condition[0].temp_F,
								'c'	:	data.current_condition[0].temp_C
							},
			'visibility'	: data.current_condition[0].visibility,
			'description'	: data.current_condition[0].weatherDesc[0].value,
			'icon'			: data.current_condition[0].weatherIconUrl[0].value,
			'wind'			: {
								'm'			: data.current_condition[0].windspeedMiles,
								'km'		: data.current_condition[0].windspeedKmph,
								'direction'	: data.current_condition[0].winddir16Point
							},
			'clouds'		: data.current_condition[0].cloudcover,
			'humidity'		: data.current_condition[0].humidity,
			'pressure'		: data.current_condition[0].pressure

		}

		@forecast.current 	= currentForecast
		@forecast.days 		= {}

		for dayforecast in data.weather

			newForecast = {
				'date'			: dayforecast.date,
				'precip_mm'		: dayforecast.precipMM,
				'temp_min'		: {
									'f'	:	dayforecast.tempMinF,
									'c'	:	dayforecast.tempMinC
								},
				'temp_max'		: {
									'f'	:	dayforecast.tempMaxF,
									'c'	:	dayforecast.tempMaxC
								},
				'description'	: dayforecast.weatherDesc[0].value,
				'icon'			: dayforecast.weatherIconUrl[0].value,
				'wind'			: {
									'm'			: dayforecast.windspeedMiles,
									'km'		: dayforecast.windspeedKmph,
									'direction'	: dayforecast.winddir16Point
								}
			}
			@forecast.days[dayforecast.date] = newForecast
			newForecast = null

	hasValidForecast: () ->
		status = no
		currentDate = new Date
		currentDate = do currentDate.yyyymmdd
		if @forecast and @forecast['current']
			if @forecast.current.date is currentDate
				status = yes
		status

	getForecastOverview: () ->
		contentText  	= @location
		validForecast 	= do @hasValidForecast
		if validForecast
			contentText =  @location + ' at ' + @forecast.current.time + ': '+@forecast.current.temp.c + '&deg;C, ' + @forecast.current.description
		contentText

	showData: () ->
		# console.log @