$ = jQuery
class AutoComplete extends EventEmitter

	@AUTOCOMPLETE_QUERY 	= "autocomplete_query_string"
	@AUTOCOMPLETE_NOTFOUND 	= "autocomplete_query_not_found"
	@autocompleteInstance	= null
	@element				= null
	@selectorID 			= null

	constructor: (inputSelectorID) ->

		@selectorID 			= inputSelectorID
		@element 				= ($ '#'+inputSelectorID)[0]
		autocompleteOptions		=
			types: ['(cities)']
		@autocompleteInstance	= new google.maps.places.Autocomplete @element, autocompleteOptions


	bindToGoogleMap: (gmapInstance) ->
		@autocompleteInstance.bindTo 'bounds', gmapInstance
		google.maps.event.addListener @autocompleteInstance, 'place_changed', @handleAutocomplete

	handleAutocomplete: () =>
		place = do @autocompleteInstance.getPlace
		if not place.geometry
			@emitEvent AutoComplete.AUTOCOMPLETE_NOTFOUND, []
			return

		for component in place.address_components
			locality 	= component.long_name if 'locality' in component.types and !locality
			country 	= component.long_name if 'country' in component.types and !country

		output =
			name : locality + ', ' + country
			coordinates	: {
				'latitude'	: place.geometry.location.lat(),
				'longitude'	: place.geometry.location.lng()
			}

		@emitEvent AutoComplete.AUTOCOMPLETE_QUERY, [output]
		return false

