-- Resolution PSP screen: 480 x 272
topScreen = 0
bottomScreen = 272
leftScreen = 0
rightScreen = 480

particle = Image.createEmpty( 2, 2 )
particle:clear( Color.new( 0, 255, 0 ) )

racketBottom = Image.load( "pong.png" )
racketBottomStartX = ( rightScreen / 2 ) - ( racketBottom:width() / 2 )
-- racketBottomStartY = ( bottomScreen - 15 ) - ( racketBottom:height() / 2 )
racketBottomStartY = bottomScreen - 20

speedX = 2
speedY = 2
gravity = 2
bounce = 2
-- Direction 1: moving to the right
-- Direction 2: moving to the left
direction = 1

x = 240
y = 0

white = Color.new( 255, 255, 255 )
retry = 0
score = 0

while true do
	screen:clear()
	pad = Controls.read()

	if retry < 1 then
		if pad:left() then
			racketBottomStartX = racketBottomStartX - 5
			screen:blit( racketBottomStartX, racketBottomStartY, racketBottom )
		elseif pad:right() then
			racketBottomStartX = racketBottomStartX + 5
			screen:blit( racketBottomStartX, racketBottomStartY, racketBottom )
		else
			screen:blit( racketBottomStartX, racketBottomStartY, racketBottom )
		end

		leftSideRacketBottomX = racketBottomStartX
		rightSideRacketBottomX = racketBottomStartX + racketBottom:width()
--		screen:print( 5, 0, leftSideRacketBottomX, white)
--		screen:print( 5, 10, rightSideRacketBottomX, white)

--		speedY = speedY + gravity
		y = y + speedY

		if y < racketBottomStartY then
			if direction == 1 then
				if x >= rightScreen then
					direction = 2
					x = x - speedX
				elseif x < rightScreen then
					x = x + speedX
				end
			elseif direction == 2 then
				if x <= leftScreen then
					direction = 1
					x = x + speedX
				elseif x > leftScreen then
					x = x - speedX
				end
			end
		elseif y == racketBottomStartY then
			score = score + 5
			if direction == 1 then
				if x >= rightScreen then
					direction = 2
					x = x - speedX
				elseif x < rightScreen then
					x = x + speedX
				end
			elseif direction == 2 then
				if x <= leftScreen then
					direction = 1
					x = x + speedX
				elseif x > leftScreen then
					x = x - speedX
				end
			end
			if x >= leftSideRacketBottomX and x <= rightSideRacketBottomX then
				speedY = speedY * -bounce
			end
		elseif y >= bottomScreen then
			retry = 1
		end

		if y < topScreen then
			y = topScreen
			speedY = bounce
		end

		screen:print( 5, 5, 'Score: ' .. score, white)
		screen:blit( x, y, particle )
	elseif retry == 1 then
		screen:print( 5, 5, 'Score: ' .. score, white)
		screen:print( 200, 121, 'GAME OVER!', white )
		screen:print( 200, 131, 'Press X to retry', white )
		screen:print( 200, 141, 'Press Start to go back to main menu', white )
	end

	if pad:cross() and retry == 1 then
		scrore = 0
		retry = 0
		x = 240
		y = 0
	elseif pad:start() and retry == 1 then
		break
	end

	screen.waitVblankStart()
	screen.flip()
end
