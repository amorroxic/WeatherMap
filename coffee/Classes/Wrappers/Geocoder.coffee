class Geocoder extends EventEmitter

	@SUCCESS 		= 'geocoder_success'
	@FAILURE 		= 'geocoder_failure'

	location		= null
	instance 		= null

	constructor: (city) ->
		location	= city
		instance 	= new google.maps.Geocoder

	perform: () ->
		console.log "Geocoder performing: " + location
		geocoderParams =
			address: location
		results = instance.geocode geocoderParams, (results, status) =>
			if status == google.maps.GeocoderStatus.OK
				locality = ''
				country = ''
				for result in results
					for component in result.address_components
						locality 	= component.long_name if 'locality' in component.types and !locality
						country 	= component.long_name if 'country' in component.types and !country

				output = {
					'location'		: locality + ', ' + country,
					'coordinates'	: {
										'latitude'	: results[0].geometry.location.lat(),
										'longitude'	: results[0].geometry.location.lng()
					}
				}
				@emitEvent Geocoder.SUCCESS, [output]
			else
				@emitEvent Geocoder.FAILURE


