class LocalStorage extends EventEmitter

	store: (key,data) ->
		localStorage.setItem(key, JSON.stringify(data))

	retrieve: (key) ->
		retrievedObject = localStorage.getItem(key)
		parsedObject = JSON.parse(retrievedObject)
		parsedObject

	remove: (key) ->
		localStorage.removeItem(key)
