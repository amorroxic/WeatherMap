$ = jQuery
class Maps extends EventEmitter

	@parentSelectorID		= null
	@parentElement			= null
	@mapInstance			= null
	@markers				= null

	@LOCATION_IS_REMOVED		= "maps_location_removed_is_me"

	constructor: (selectorID) ->

		@markers 			= []
		@parentSelectorID 	= selectorID
		@parentElement 		= ($ '#'+selectorID)[0]
		window.mapsWrapper 	= @

		dublin = new google.maps.LatLng 53.3494426, -6.260082499999953
		mapOptions =
			zoom: 4
			center: dublin
			maxZoom: 5
			mapTypeId: google.maps.MapTypeId.SATELLITE

		@mapInstance = new google.maps.Map @parentElement, mapOptions

	getGoogleMapsInstance: () ->
		@mapInstance

	addCityToMap: (params) ->

		forecastIcon = @addForecastIcon params

		myOptions =
			id: params.id
			content: forecastIcon
			disableAutoPan: true
			zIndex: null
			boxClass: 'tooltip'
			closeBoxURL: 'img/close.png'
			closeBoxMargin: '-25px -22px 0 0'
			position: new google.maps.LatLng params.coords.latitude, params.coords.longitude
			isHidden: false
			pane: "floatPane"
			enableEventPropagation: false
			map: @mapInstance

		box = new InfoBox myOptions

		markerSymbol = new google.maps.Marker
			map: @mapInstance
			position: new google.maps.LatLng params.coords.latitude, params.coords.longitude
			visible: false

		@markers.push {'id':params.id, 'city':params.name, 'box': box, 'symbol': markerSymbol}
		do @placeMarkersOnMap

	addForecastIcon: (params) ->

		contentText = params.overview
		boxText = $('<div></div>').attr('rel',params.id).html(contentText)

		if params.forecast.current?
			forecastImage = $('<img></img>').attr('src',params.forecast.current.icon).width(26)
			holder = $('<div></div>').addClass('forecast-icon')
			forecastImage.appendTo holder
			holder.appendTo boxText

		if params.forecast.days?
			forecastHolder = $('<div></div>').addClass('forecast-prognose').addClass('hide').attr('id','prognose-'+params.id)
			for day of params.forecast.days
				if day is params.forecast.current.date
					prognoseFor = 'Today: '
				else
					prognoseFor = 'Tomorrow: '
				currentForecast = params.forecast.days[day]
				contentText = prognoseFor + 'Min ' + currentForecast.temp_min.c + '&deg;C - Max '+currentForecast.temp_max.c + '&deg;C, ' + currentForecast.description
				holder = $('<div></div>').addClass('forecast').html(contentText)
				holder.appendTo forecastHolder
			forecastHolder.appendTo boxText


		boxText.bind 'mouseover', (e) ->
			$('.tooltip').each ->
				$(this).css('background-color','#40506c')
			parent = do $(@).parent
			parent.css('background-color','#000')
			elementID = $(e.currentTarget).attr 'rel'
			$('.forecast-prognose').each ->
				$(this).removeClass('show').addClass('hide')
			$('#prognose-'+elementID).removeClass('hide').addClass('show')

		boxText[0]

	updateCity: (params) ->
		if @markers.length
			for marker in @markers
				if marker.id is params.id
					forecastIcon = @addForecastIcon params
					marker['box'].setContent forecastIcon

	clearOverlays: () ->
		$('.tooltip').each ->
			$(this).css('background-color','#40506c')
		$('.forecast-prognose').each ->
			$(this).removeClass('show').addClass('hide')
		if @markers.length
			for marker in @markers
				google.maps.event.clearListeners(marker['box'], 'closeclick');
				marker['box'].close
				marker['symbol'].close

	placeMarkersOnMap: () ->
		do @clearOverlays
		if @markers.length
			bounds = new google.maps.LatLngBounds
			for marker in @markers
				position = do marker['box'].getPosition
				bounds.extend position;
				google.maps.event.addListener marker['box'], 'closeclick', @locationRemoved
				marker['box'].open @mapInstance, marker['symbol']

			@mapInstance.fitBounds bounds

	locationRemoved: () ->
		content = do @.getContent
		cityID = $(content).attr('rel')
		window.mapsWrapper.removeMarker cityID

	removeMarker: (cityID) ->
		for marker in @markers
			if marker.id is +cityID
				google.maps.event.clearListeners(marker['box'], 'closeclick');
		@markers = @markers.filter (marker) -> marker.id isnt +cityID
		@emitEvent Maps.LOCATION_IS_REMOVED, [cityID]
		do @placeMarkersOnMap



