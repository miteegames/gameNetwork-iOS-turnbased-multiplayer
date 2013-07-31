gameNetwork-iOS-turnbased-multiplayer
=====================================
Files:

main.lua - The main entry point of the application.  This file will log the user into gamecanter.  Afterwards it will take you to menu-scene.lua.

menu-scene.lua - This will let the player create a game or join a game.  Creating a game will allow take the player to select-players-scene.lua.  Joining a game will show the game center popup which will let the player continue a game.

select-players-scene.lua - This scene will let the user choose the player you want to play with.  Choosing a player will invite that player to a game.  This will then take you to game-scene.lua.

game-scene.lua - This will handle all the multiplayer items within the game.  For example this will end a players turn, checking to see if a player has won the game, seeing if someone has quit the game, etc.  This will send the moves to game-logic.lua.

game-logic.lua - This will handle the player tap on the gems and decide if that is a valid tap.  This will also decide how many points the tap is.


Items implemented:

gamecenter.request("loadCurrentPlayer")

gamecenter.request("createMatch")

gamecenter.request("quitMatch")

gamecenter.request("endMatch")

gamecenter.request("setEventListener")

gamecenter.request("loadMatchData")

gamecenter.request("endTurn")

gamecenter.request("loadMatches")


gamecenter.show("matches")

gamecenter.show("createMatch")


Items that can be implmemented

gamecenter.request("removeMatch")


API Docs:

http://docs.coronalabs.com/daily/api/library/gameNetwork/index.html
