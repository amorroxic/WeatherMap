class Ajax extends EventEmitter

	@LOAD_FAILED 	= 'ajax_load_failed'
	@LOAD_SUCCESS 	= 'ajax_load_success'

	endPoint	= null

	constructor: (uri) ->
		endPoint = uri

	perform: (queryObject) ->

		jQuery.ajax
			url: endPoint
			type: 'GET'
			dataType: 'jsonp'
			data: queryObject
			error: (jqXHR, textStatus, errorThrown) =>
				@emitEvent Ajax.LOAD_FAILED, [textStatus]
			success: (data, textStatus, jqXHR) =>
				@emitEvent Ajax.LOAD_SUCCESS, [data]
