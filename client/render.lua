local font = dxCreateFont("files/myriadproregular.ttf", 14, false, "default")

function render3dTexts()
	local texts = Buffer3dText.getVisibleTexts()

	if texts then
		for _, v in ipairs(texts) do
			local x, y, z = getElementPosition(localPlayer)
			local distance = getDistanceBetweenPoints3D(x, y, z, v.position[1], v.position[2], v.position[3])

			if distance <= v.distance then
				local is_los = true
				if v.los then
					is_los = isLineOfSightClear(x, y, z, v.position[1], v.position[2], v.position[3])
				end

				if (v.los and is_los) or (not v.los) then
					local scale = ((v.distance - distance) / v.distance)
					local alpha = 255 * scale

					scale = scale * v.scale
					if scale < 0.7 then scale = 0.7 end
					if scale > v.scale then scale = v.scale end

					local red = bitExtract(v.color, 0, 8) 
					local green = bitExtract(v.color, 8, 8) 
					local blue = bitExtract(v.color, 16, 8)


					dxDrawText( v.text, v["screen_position"]["x"], v["screen_position"]["y"], v["screen_position"]["x"], v["screen_position"]["y"], tocolor(red, green, blue, alpha), scale, font, "center", "top", false, false, false, true, true)
				end 
			end
		end
	end
end

addEventHandler("onClientPreRender", root, render3dTexts)
