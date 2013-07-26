local storyboard = require( "storyboard" )
local json = require( "json" )

local scene = storyboard.newScene()
 
local peopleChooser

local bg, text1, text2, text3;
local _W = display.contentWidth 
local _H = display.contentHeight

-- the match id, as a storyboard variable
storyboard.matchId = nil
storyboard.otherPlayerId = nil
storyboard.myPlayerId = nil

-- Called when the scene's view does not exist
function scene:createScene( event )
	local screenGroup = self.view
end

-- Called when the scene's view is about to appear
function scene:willEnterScene( event )
    local screenGroup = self.view
end


-- Called when the scene's view appeared 
function scene:enterScene( event )

	local loginText

    local screenGroup = self.view

    storyboard.purgeScene( "game-scene" )


    local function roomListener(roomEvent)
    	local function loadLocalPlayerListener(loadLocalPlayerEvent)
    		storyboard.matchId = roomEvent.data.matchID
			storyboard.myPlayerId = loadLocalPlayerEvent.data.playerID
			
			local options =
			{
				effect = "fade",
				time = 400
			}

			storyboard.gotoScene( "game-scene", options )
    	end

    	storyboard.gn.request("loadLocalPlayer", {listener = loadLocalPlayerListener})
    end

	-- touch listener for the push button
	local function buttonPressed( buttonEvent )
		local target = buttonEvent.target
		
		if buttonEvent.phase == "began" then
			target:setTextColor( 245, 127, 32 )
		elseif buttonEvent.phase == "ended" then
			if target.tag == 1 then
				storyboard.gn.show("matches", {
					listener = roomListener,
					minPlayers = 2,
					maxPlayers = 2
				})
			elseif target.tag == 2 then

				local function friendsListener(friendsLoadedEvent)
					local function playersListener(playersLoadedEvent)
						storyboard.friendsArray = playersLoadedEvent.data
						storyboard.gotoScene( "select-players-scene", options )
					end
					storyboard.gn.request("loadPlayers", {listener = playersListener, playerIDs = friendsLoadedEvent.data})
				end
				storyboard.gn.request("loadFriends", {listener = friendsListener})
			end
			-- reset the button color
			target:setTextColor( 255, 255, 255 )
		end
	end
	
	local screenWidth = display.contentWidth - (display.screenOriginX*2)
	local screenRealWidth = screenWidth / display.contentScaleX

	local screenHeight = display.contentHeight - (display.screenOriginY*2)
	local screenRealHeight = screenHeight / display.contentScaleY

	local bg = display.newImage( storyboard.iSheet ,1)
	bg:setReferencePoint( display.CenterReferencePoint )
	bg.x = display.contentWidth * 0.5
	bg.y = display.contentHeight * 0.5
	bg.xScale, bg.yScale = storyboard.globalScale, storyboard.globalScale
	screenGroup:insert( bg )
	
	local logo = display.newImage( storyboard.iSheet, 6)
	logo:setReferencePoint( display.CenterReferencePoint )
	logo.xScale, logo.yScale = storyboard.globalScale, storyboard.globalScale
	logo.x = display.contentWidth * 0.5
	logo.y = 120
	screenGroup:insert( logo )
	
	local joinText = display.newText( screenGroup, "JOIN MATCH", display.contentWidth * 0.5, display.contentHeight - 270, "Futura-CondensedExtraBold", 30 )
	joinText:setReferencePoint( display.CenterReferencePoint )
	joinText.x = display.contentWidth * 0.5
	joinText:setTextColor( 255, 255, 255 )
	joinText:addEventListener( "touch", buttonPressed )
	joinText.tag = 1
	
	local hostText = display.newText( screenGroup, "CREATE MATCH", display.contentWidth * 0.5, display.contentHeight - 200, "Futura-CondensedExtraBold", 30 )
	hostText:setReferencePoint( display.CenterReferencePoint )
	hostText.x = display.contentWidth * 0.5
	hostText:setTextColor( 255, 255, 255 )
	hostText:addEventListener( "touch", buttonPressed )
	hostText.tag = 2

end

function scene:exitScene( event )
    local screenGroup = self.view
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