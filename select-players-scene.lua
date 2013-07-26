local storyboard = require( "storyboard" )

local scene = storyboard.newScene()
-- Called when the scene's view does not exist
function scene:createScene( event )
	local screenGroup = self.view
end

-- Called when the scene's view is about to appear
function scene:willEnterScene( event )
    local screenGroup = self.view
end

local list, titleBar, titleText, backButton

-- Called when the scene's view appeared 
function scene:enterScene( event )

	local screenGroup = self.view
	
	storyboard.purgeScene( "game-scene" )

	-- Import the widget library
	local widget = require( "widget" )

	local options =
	{
		effect = "fade",
		time = 400
	}

	--Create a group to hold our widgets & images
	
	-- The gradient used by the title bar
	local titleGradient = graphics.newGradient( 
		{ 189, 203, 220, 255 }, 
		{ 89, 116, 152, 255 }, "down" )

	-- Create toolbar to go at the top of the screen
	titleBar = display.newRect( 0, 0, display.contentWidth, 32 )
	titleBar.y = display.statusBarHeight + ( titleBar.contentHeight * 0.5 )
	titleBar:setFillColor( titleGradient )
	titleBar.y = display.screenOriginY + titleBar.contentHeight * 0.5


	backButton = widget.newButton
	{
		top = titleBar.y-16,
		left = 0,
		width = display.contentWidth/5, 
		height = 32,
		label = "Back",
		onRelease = function (event) storyboard.gotoScene( "menu-scene", options ) end
	}


	-- create embossed text to go on toolbar
	titleText = display.newEmbossedText( "Select Other Player", 0, 0, native.systemFontBold, 20 )
	titleText:setReferencePoint( display.CenterReferencePoint )
	titleText:setTextColor( 255 )
	titleText.x = 160
	titleText.y = titleBar.y

	-- Handle row rendering
	local function onRowRender( event )
		local phase = event.phase
		local row = event.row
		
		local rowTitle = display.newText( row, storyboard.friendsArray[row.index].alias, 0, 0, native.systemFontBold, 16 )
		rowTitle.x = row.x - ( row.contentWidth * 0.5 ) + ( rowTitle.contentWidth * 0.5 )
		rowTitle.y = row.contentHeight * 0.5
		
	end

	-- Hande row touch events
	local function onRowTouch( event )
		local phase = event.phase
		local row = event.target
		
		if "release" == phase then
			local function roomListener(roomEvent)
		    	local function loadLocalPlayerListener(loadLocalPlayerEvent)
		    		storyboard.matchId = roomEvent.data.matchID

					storyboard.myPlayerId = loadLocalPlayerEvent.data.playerID

					storyboard.gotoScene( "game-scene", options )
		    	end

		    	storyboard.gn.request("loadLocalPlayer", {listener = loadLocalPlayerListener})

		    end

		    -- There is an issue with the following iOS versions where inviting players would cause the view to show waiting and 
		    -- the game won't start
			local iOSVersion = system.getInfo( "platformVersion" )
			if iOSVersion == "6.0" or iOSVersion == "6.0.1" or iOSVersion == "6.0.2" then
				storyboard.gn.request("createMatch", {
						listener = roomListener,
						playerIDs = {storyboard.friendsArray[row.index].playerID},
						minPlayers = 2,
						maxPlayers = 2,
					})
			else
				storyboard.gn.show("createMatch", {
						listener = roomListener,
						playerIDs = {storyboard.friendsArray[row.index].playerID},
						minPlayers = 2,
						maxPlayers = 2,
					})
			end
		end
	end

	-- Create a tableView
	list = widget.newTableView
	{
		top = 38,
		width = 420, 
		height = 448,
		hideBackground = true,
		onRowRender = onRowRender,
		onRowTouch = onRowTouch,
	}

	for i = 1, #storyboard.friendsArray, 1 do
		list:insertRow
		{
			height = 72,
			rowColor = 
			{ 
				default = { 255, 255, 255, 0 },
			},
		}
	end

end

function scene:exitScene( event )
	display.remove(backButton)
    display.remove(list)
    display.remove(titleBar)
    display.remove(titleText)
end
 
-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )
 
-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener( "willEnterScene", scene )
 
-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )
 
-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )
 
---------------------------------------------------------------------------------
 
return scene