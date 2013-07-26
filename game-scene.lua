local storyboard = require( "storyboard" )
local scene = storyboard.newScene()
local json = require("json")

local gl = require( "game-logic" )

local SCORE_LIMIT = 1000

local _W = display.contentWidth 
local _H = display.contentHeight

local gameOverLayout
local gameOverText1
local gameOverText2
local gameOverText3

local p1score, p2score
local p1total = 0
local p2total = 0
local player1ID, player2ID

-- These are used because during automatch player slot might not have a playerID property.
-- The index is used to reference player slots without a playerID
local myIndex, theirIndex

local turnText

local backButton
local quitButton

-- the number of moves played
local numberOfMoves = 0

local function imPlayer1()
	return (player1ID and player1ID == storyboard.myPlayerId) or player1ID == nil
end

local function encodeData()
	local p1ID, p2ID
	if imPlayer1() then
		p1ID = storyboard.myPlayerId
		p2ID = player2ID
	else
		p1ID = player1ID
		p2ID = storyboard.myPlayerId
	end

	local allData = {
		tableData = gl.gemsTable.moveContent,
		player1 = p1total,
		player2 = p2total,
		player1ID = p1ID,
		player2ID = p2ID
	}
	return json.encode(allData) 
end


local function decodeData(data)	
	player1ID = data.player1ID
	player2ID = data.player2ID
	p1total = data.player1
	p2total = data.player2

	if imPlayer1() then

		p1score.text = string.format( "YOU: %6.0f", p1total )
		p2score.text = string.format( " P2: %6.0f", p2total )
		gameOverText2.text = string.format( "YOU: %6.0f", p1total )
		gameOverText3.text = string.format( " P2: %6.0f", p2total )
	else
		p1score.text = string.format( "YOU: %6.0f", p2total )
		p2score.text = string.format( " P2: %6.0f", p1total )
		gameOverText2.text = string.format( "YOU: %6.0f", p2total )
		gameOverText3.text = string.format( " P2: %6.0f", p1total )
	end

	
	
end


local function gameOver ()

	gameOverLayout.alpha = 0.8
	gameOverText1.alpha = 1
	gameOverText2.alpha = 1
	gameOverText3.alpha = 1

	if player1ID and player1ID == storyboard.myPlayerId and p1total > SCORE_LIMIT then
		storyboard.gn.request("endMatch", {
			matchID = storyboard.matchId,
			data = encodeData(),
			outcome = {
				[myIndex] = "lost",
				[theirIndex] = "won",
			},
		})
	else
		storyboard.gn.request("endMatch", {
			matchID = storyboard.matchId,
			data = encodeData(),
			outcome = {
				[theirIndex] = "won",
				[myIndex] = "lost",
			},
		})
	end
end

local function handleLogic( event )
	if event.name == "gemTapped" then
		-- gem has been tapped
		-- we push the move
		gl.gemsTable.moveContent.isFirstMove = nil
		gl.gemsTable.moveContent.params = { event.params[1], event.params[2], event.params[3], numberOfMoves }
		
		if imPlayer1() then
			p1total = p1total + event.params[3]
			p1score.text = string.format( "YOU: %6.0f", p1total )
			gameOverText2.text = string.format( "YOU: %6.0f", p1total )
			
		else
			p2total = p2total + event.params[3]
			p1score.text = string.format( "YOU: %6.0f", p2total )
			gameOverText2.text = string.format( "YOU: %6.0f", p2total )
		end
		if p1total > SCORE_LIMIT or p2total > SCORE_LIMIT then
			gameOver()
			return
		end

		storyboard.gn.request("endTurn", 
		{
			nextParticipant = {theirIndex},
			matchID = storyboard.matchId,
			data = encodeData()
		})
		
		numberOfMoves = numberOfMoves + 1
		
		gl.overlay.isVisible = true
		backButton:toFront()
		quitButton:toFront()
		turnText.text = "Wait for your turn"
	end
end

local function onTouchGameOverScreen ( self, event )

	if event.phase == "began" then
		storyboard.gotoScene( "menu-scene", "fade", 400	)
		return true
	end
end 

local function processMove( moves )
	-- if it is the first move
	if nil ~= moves then
		-- not a first move
		gl.receivedTable = moves.moves
		gl.redrawTable()
		if imPlayer1() then
			p2score.text = string.format( " P2: %6.0f", p2total )
			gameOverText3.text = string.format( " P2: %6.0f", p2total )
		else
			p2score.text = string.format( " P2: %6.0f", p1total )
			gameOverText3.text = string.format( " P2: %6.0f", p1total )
		end
		if p1total > SCORE_LIMIT or p2total > SCORE_LIMIT then
			gameOver()
			return
		end
		numberOfMoves = numberOfMoves + 1
		gl.overlay.isVisible = false
		backButton:toFront()
		quitButton:toFront()
		turnText.text = "It is your turn"
	end
end

-- Called when the scene's view does not exist:
function scene:createScene( event )

	p1total = 0
	p2total = 0

	local screenGroup = self.view

	groupGameLayer = display.newGroup()
	groupEndGameLayer = display.newGroup()

	gl.init( storyboard.iSheet, groupGameLayer, handleLogic )

	-- Creates a new random table
	local function initTable()
		-- reseed
		math.randomseed( os.time() )
		for i = 1, 8, 1 do
			gl.gemsTable[i] = {}
			for j = 1, 8, 1 do
				gl.gemsTable[i][j] = gl.newGem( i,j, nil)
			end
		end
		
		gl.overlay:toFront()
		backButton:toFront()
		quitButton:toFront()
	end

	-- Loads a table
	local function loadTable(moves)
		for i = 1, 8, 1 do
			gl.gemsTable[i] = {}
			for j = 1, 8, 1 do
				gl.gemsTable[i][j] = gl.newGem( i,j, moves.moves[i][j])
			end
		end
		
		gl.overlay:toFront()
		backButton:toFront()
		quitButton:toFront()
	end

	local function matchDataListener(matchDataEvent)
		if matchDataEvent.data.data and matchDataEvent.data.data ~= "" then

			local allData = json.decode(matchDataEvent.data.data)
			
			decodeData(allData)

			loadTable(allData.tableData)

			if matchDataEvent.data.currentParticipant.playerID == storyboard.myPlayerId then
				gl.overlay.isVisible = false
			else
				gl.overlay.isVisible = true
				turnText.text = "Wait for your turn"
			end
		else
			initTable()
		end

		for i = 1, #matchDataEvent.data.participants, 1 do
			if matchDataEvent.data.participants[i].playerID == storyboard.myPlayerId then
				myIndex = matchDataEvent.data.participants[i].index
			else
				theirIndex = matchDataEvent.data.participants[i].index
			end
		end

	end

	storyboard.gn.request("loadMatchData", 
	{
		listener = matchDataListener,
		matchID = storyboard.matchId
	})

	local function yourTurnListener(turnEvent)
		-- If its the match the current player is in then we can update the state of the game without informing the user
		if turnEvent.type == "playerTurn" then
			if storyboard.matchId == turnEvent.data.matchID then
				local allData = json.decode(turnEvent.data.data)

				decodeData(allData)

				processMove(allData.tableData)
			else
				-- If its not the match the crrent player is in then we want to inform the user because they might want to play that match
				native.showAlert("Your Turn", "Its your turn in another match", {"OK"})
			end
		elseif turnEvent.type == "matchEnded" then
			local allData = json.decode(turnEvent.data.data)
		
			decodeData(allData)

			gameOver()
		end
	end

	storyboard.gn.request("setEventListener", 
	{
		listener = yourTurnListener
	})

	local function onBackButton(backButtonEvent)
		if backButtonEvent.phase == "ended" or backButtonEvent.phase == "tap" then
			storyboard.gotoScene( "menu-scene", "fade", 400	)

			-- this will remove the listener
			storyboard.gn.request("setEventListener")
		end
	end

	local function onQuitButton(quitButtonEvent)
		if quitButtonEvent.phase == "ended" or quitButtonEvent.phase == "tap" then
			local function matchDataListener(matchDataEvent)
				local boolean otherPlayerQuit = false
				-- Checks the status of the other participant, if they're already done with the game then we can end the match instead of quitting
				for i = 1, #matchDataEvent.data.participants, 1 do
					if storyboard.otherPlayerId == matchDataEvent.data.participants[i].playerID and matchDataEvent.data.participants[i].status == "done" then
						otherPlayerQuit = true
					end
				end

				if otherPlayerQuit then
					storyboard.gn.request("endMatch", {
						matchID = storyboard.matchId,
						data = encodeData(),
						outcome = {
							theirIndex = "lost",
							myIndex = "won",
						},
					})
				else
					storyboard.gn.request("quitMatch", {
						matchID = storyboard.matchId,
						data = encodeData(),
						outcome = "lost",
						nextParticipant = {theirIndex},
					})
				end

				storyboard.gotoScene( "menu-scene", "fade", 400	)

				-- this will remove the listener
				storyboard.gn.request("setEventListener")
			end

			storyboard.gn.request("loadMatchData", {
				matchID = storyboard.matchId,
				listener = matchDataListener
			})
		end
	end

	backButton = display.newText( "BACK" , 10, 5, "Futura-CondensedExtraBold", 50 * storyboard.globalScale )
	backButton:setTextColor(255, 255, 255, 255)
	backButton:addEventListener( "touch", onBackButton )
	backButton:addEventListener( "tap", onBackButton )

	groupGameLayer:insert ( backButton )
	
	quitButton = display.newText( "QUIT" , 240, 5, "Futura-CondensedExtraBold", 50 * storyboard.globalScale )
	quitButton:setTextColor(255, 255, 255, 255)
	quitButton:addEventListener( "touch", onQuitButton )
	quitButton:addEventListener( "tap", onQuitButton )

	groupGameLayer:insert ( quitButton )

	p1score = display.newText( "P1:" , 40, 40, "Futura-CondensedExtraBold", 25 * storyboard.globalScale )
	p1score.text = string.format( "YOU: %6.0f", 0 )
	p1score:setReferencePoint(display.TopLeftReferencePoint)
	p1score.x = 10
	p1score:setTextColor(255, 255, 255, 255)
		
	groupGameLayer:insert ( p1score )
	
	p2score = display.newText( "P2:" , 40, 40, "Futura-CondensedExtraBold", 25 * storyboard.globalScale )
	p2score.text = string.format( " P2: %6.0f", 0 )
	p2score:setReferencePoint(display.TopLeftReferencePoint)
	p2score.x = 240
	p2score:setTextColor(255, 255, 255, 255)
		
	groupGameLayer:insert ( p2score )

	gameOverLayout = display.newRect( 0, 0, 320, 480)
	gameOverLayout:setFillColor( 0, 0, 0 )
	gameOverLayout.alpha = 0
	
	gameOverText1 = display.newText( "GAME OVER", 0, 0, "Futura-CondensedExtraBold", 60 * storyboard.globalScale )
	gameOverText1:setTextColor( 255 )
	gameOverText1:setReferencePoint( display.CenterReferencePoint )
	gameOverText1.x, gameOverText1.y = _W * 0.5, _H * 0.5 -150
	gameOverText1.alpha = 0

	gameOverText2 = display.newText( "P1: ", 0, 0, "Futura-CondensedExtraBold", 48 * storyboard.globalScale )
	gameOverText2.text = string.format( "YOU: %6.0f", p1total )
	gameOverText2:setTextColor( 255 )
	gameOverText2:setReferencePoint( display.CenterReferencePoint )
	gameOverText2.x, gameOverText2.y = _W * 0.5, _H * 0.5 - 50
	gameOverText2.alpha = 0

	gameOverText3 = display.newText( "P1: ", 0, 0, "Futura-CondensedExtraBold", 48 * storyboard.globalScale )
	gameOverText3.text = string.format( " P2: %6.0f", p2total )
	gameOverText3:setTextColor( 255 )
	gameOverText3:setReferencePoint( display.CenterReferencePoint )
	gameOverText3.x, gameOverText3.y = _W * 0.5, _H * 0.5 + 10
	gameOverText3.alpha = 0
	
	gameOverLayout.touch = onTouchGameOverScreen
	gameOverLayout:addEventListener( "touch", gameOverLayout )


	groupEndGameLayer:insert ( gameOverLayout )
	groupEndGameLayer:insert ( gameOverText1 )
	groupEndGameLayer:insert ( gameOverText2 )
	groupEndGameLayer:insert ( gameOverText3 )

	turnText = display.newText( "It is your turn" , 40, display.contentHeight - 50, "Futura-CondensedExtraBold", 25 * storyboard.globalScale )
	turnText:setReferencePoint(display.CenterReferencePoint)
	turnText.x = display.contentWidth * 0.5
	turnText:setTextColor(255, 255, 255, 255)
		
	groupGameLayer:insert ( turnText )

	-- insterting display groups to the screen group (storyboard group)
	screenGroup:insert ( groupGameLayer )
	screenGroup:insert ( groupEndGameLayer )
	
	gl.overlay.isVisible = false
	backButton:toFront()
	quitButton:toFront()
end
 
-- Called BEFORE scene has moved onscreen:
function scene:willEnterScene( event )
		local screenGroup = self.view
		
		-----------------------------------------------------------------------------
				
		--		This event requires build 2012.782 or later.
		
		-----------------------------------------------------------------------------
		
end
 
-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
		local screenGroup = self.view
		
		-----------------------------------------------------------------------------
				
		--		INSERT code here (e.g. start timers, load audio, start listeners, etc.)
		
		-----------------------------------------------------------------------------
	
	-- remove previous scene's view
		
	storyboard.purgeScene( "menu-scene" )
	storyboard.purgeScene( "select-players-scene" )

	print( "1: enterScene event" )

end
 
 
-- Called when scene is about to move offscreen:
function scene:exitScene( event )
		local screenGroup = self.view

end
 
-- Called AFTER scene has finished moving offscreen:
function scene:didExitScene( event )
		local screenGroup = self.view
		
		-----------------------------------------------------------------------------
				
		--		This event requires build 2012.782 or later.
		
		-----------------------------------------------------------------------------
		
end
 
 
-- Called prior to the removal of scene's "view" (display group)
function scene:destroyScene( event )
		local screenGroup = self.view
		
		-----------------------------------------------------------------------------
		
		--		INSERT code here (e.g. remove listeners, widgets, save state, etc.)
		
		-----------------------------------------------------------------------------
		
end
 
-- Called if/when overlay scene is displayed via storyboard.showOverlay()
function scene:overlayBegan( event )
		local screenGroup = self.view
		local overlay_scene = event.sceneName  -- overlay scene name
		
		-----------------------------------------------------------------------------
				
		--		This event requires build 2012.797 or later.
		
		-----------------------------------------------------------------------------
		
end
 
-- Called if/when overlay scene is hidden/removed via storyboard.hideOverlay()
function scene:overlayEnded( event )
		local screenGroup = self.view
		local overlay_scene = event.sceneName  -- overlay scene name
 
		-----------------------------------------------------------------------------
				
		--		This event requires build 2012.797 or later.
		
		-----------------------------------------------------------------------------
		
end
 
 
 
---------------------------------------------------------------------------------
-- END OF YOUR IMPLEMENTATION
---------------------------------------------------------------------------------
 
-- "createScene" event is dispatched if scene's view does not exist
scene:addEventListener( "createScene", scene )
 
-- "willEnterScene" event is dispatched before scene transition begins
scene:addEventListener( "willEnterScene", scene )
 
-- "enterScene" event is dispatched whenever scene transition has finished
scene:addEventListener( "enterScene", scene )
 
-- "exitScene" event is dispatched before next scene's transition begins
scene:addEventListener( "exitScene", scene )
 
-- "didExitScene" event is dispatched after scene has finished transitioning out
scene:addEventListener( "didExitScene", scene )
 
-- "destroyScene" event is dispatched before view is unloaded, which can be
-- automatically unloaded in low memory situations, or explicitly via a call to
-- storyboard.purgeScene() or storyboard.removeScene().
scene:addEventListener( "destroyScene", scene )
 
-- "overlayBegan" event is dispatched when an overlay scene is shown
scene:addEventListener( "overlayBegan", scene )
 
-- "overlayEnded" event is dispatched when an overlay scene is hidden/removed
scene:addEventListener( "overlayEnded", scene )
 
---------------------------------------------------------------------------------
 
return scene