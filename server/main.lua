Texts = {}

function createText(x, y, z, content, color, distance, scale, font, los)
	local text = {}

	text.position = {x, y, z}
	text.text = content
	text.color = color
	text.distance = distance or 20.0
	text.scale = scale or 1.0
	text.font = font or "default"
	text.los = los or false

	Texts[#Texts+1] = text

	text.serverid = #Texts

	return #Texts
end

function removeText(id)
	if Texts[id] then
		Texts[id] = nil

		triggerClientEvent("on3dTextDeletion", root, id)
	end
end

function getTextByID(id)
	if Texts[id] then return Texts[id] end

	return false
end

function handleChunksSending(bounds)
	local response = {}
	for k, v in ipairs(Texts) do
		if (bounds[1] ~= nil and (v.position[1] >= bounds[1][1] and v.position[1] <= bounds[1][3] and v.position[2] <= bounds[1][2] and v.position[2] >= bounds[1][4]))
			or (bounds[2] ~= nil and (v.position[1] >= bounds[2][1] and v.position[1] <= bounds[2][3] and v.position[2] <= bounds[2][2] and v.position[2] >= bounds[2][4])) then

			v.serverid = k
			table.insert(response, v)

		end
	end

	triggerClientEvent( client, "onRequested3dTextChunkDataReceived", root, response)
end

addEvent("onClientRequest3dTextChunkData", true)
addEventHandler( "onClientRequest3dTextChunkData", root, handleChunksSending)

addEventHandler ( "onResourceStart", resourceRoot, function ()
	createText(-706.0, 960.0, 13.0, "Test string", 0x3486EBFF, 20.0)
	createText(-708.0, 958.0, 13.0, "Test string", 0xEB3A34FF, 20.0)
end)
