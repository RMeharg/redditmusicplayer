ProgressBar = Backbone.Model.extend
	defaults:
		loaded: 0
		current: 0
		duration: 60
		currentSongID: -1
	setDuration: (data) ->
		@set "duration", data
		@set "current", 0
	setLoaded: (data) ->
		@set "loaded", data
	setCurrent: (data) ->
		@set "current", data
	change: (index, song) ->
		if song.get("id") isnt @get("currentSongID") and song.get("playable") is true
			@setCurrent 0
			@setLoaded 0
			@setDuration 60
			@set "currentSongID", song.get "id"
			$(".controls .progress").removeClass "soundcloud"
	enableSoundcloud: (waveform) ->
		$(".controls .progress").addClass "soundcloud"
		$(".controls .progress .waveform").css "-webkit-mask-box-image", "url(#{waveform})"
	initialize: () ->
		console.log "ProgressBar :: Ready" if FLAG_DEBUG
		@listenTo RMP.dispatcher, "song:change", @change
		@listenTo RMP.dispatcher, "progress:current", @setCurrent
		@listenTo RMP.dispatcher, "progress:loaded", @setLoaded
		@listenTo RMP.dispatcher, "progress:duration", @setDuration
		

ProgressBarView = Backbone.View.extend
	events:
		"mousemove .progress": "seeking"
		"mousedown .progress": "startSeeking"
	justSeeked: false
	startSeeking: (e) ->
		RMP.dragging = true
		@percentage = e.offsetX / @$(".progress").outerWidth()
		@justSeeked = true
	seeking: (e) ->
		return if not @justSeeked # mousedown didn't start on progressbar, return

		@percentage = e.offsetX / @$(".progress").outerWidth()

		if (RMP.dragging) # mouse is down, seek without playing
			RMP.dispatcher.trigger "progress:set", @percentage, !RMP.dragging

		@$(".progress .current").css("width", @percentage * 100 + "%")
	stopSeeking: () ->
		return if not @justSeeked
		
		RMP.dispatcher.trigger "progress:set", @percentage, !RMP.dragging
		console.log "ProgressBarView :: Seek :: #{@percentage*100}%" if FLAG_DEBUG and RMP.dragging is false

		@justSeeked = false
	toMinSecs: (secs) ->
		hours = Math.floor(secs / 3600)
		if hours
			mins = Math.floor((secs / 60) - hours * 60)
			secs = Math.floor(secs % 60)
			"#{String('0'+hours).slice(-2)}:#{String('0'+mins).slice(-2)}:#{String('0'+secs).slice(-2)}"
		else 
			mins = Math.floor(secs / 60)
			secs = Math.floor(secs % 60)
			"#{String('0'+mins).slice(-2)}:#{String('0'+secs).slice(-2)}"
	resize: () ->
		itemWidth = $(".controls .left .item").outerWidth()
		@$(".progress").css("width", $("body").innerWidth() - itemWidth*6)
	render: () ->
		# set end time
		@$(".end.time").text @toMinSecs @model.get("duration")

		# set loaded progress
		@$(".progress .loaded").css("width", @model.get("loaded") * 100 + "%")

		# set current
		@$(".start.time").text @toMinSecs @model.get("current")
		@$(".progress .current").css("width", @model.get("current") / @model.get("duration") * 100 + "%")
	initialize: () ->
		@resize()
		console.log "ProgressBarView :: Ready" if FLAG_DEBUG
		@listenTo @model, "change", @render
		@listenTo RMP.dispatcher, "app:resize", @resize
		@listenTo RMP.dispatcher, "events:stopDragging", @stopSeeking

RMP.progressbar = new ProgressBar
RMP.progressbarview = new ProgressBarView
	el: $(".controls .middle.menu")
	model: RMP.progressbar

Button = Backbone.View.extend
	events:
		"click": "click"
	click: (e) ->
		RMP.dispatcher.trigger @attributes.clickEvent, e
	stateChange: (data) ->
		console.log "Button :: StateChange", data if FLAG_DEBUG
		if @checkState(data) is true then @$el.addClass "active" else @$el.removeClass "active"
	initialize: () ->
		@checkState = @attributes.checkState
		@listenTo RMP.dispatcher, @attributes.listenEvent, @stateChange if @attributes.listenEvent?

Buttons = Backbone.Model.extend
	initialize: () ->
		@backward = new Button
			el: $(".controls .backward.button")
			attributes:
				clickEvent: "controls:backward"
		@forward = new Button
			el: $(".controls .forward.button")
			attributes:
				clickEvent: "controls:forward"
		@play = new Button
			el: $(".controls .play.button")
			attributes:
				clickEvent: "controls:play"
				listenEvent: "player:playing player:paused player:ended"
				checkState: (player) ->
					player = RMP.player.controller if (player is window) 
					if player.type is "youtube"
						return player.player.getPlayerState() == 1
					else
						return player.playerState is "playing"
		@shuffle = new Button
			el: $(".controls .shuffle.button")
			attributes:
				clickEvent: "controls:shuffle"
				listenEvent: "player:shuffle"
		@repeat = new Button
			el: $(".controls .repeat.button")
			attributes:
				clickEvent: "controls:repeat"
				listenEvent: "player:repeat"

RMP.buttons = new Buttons