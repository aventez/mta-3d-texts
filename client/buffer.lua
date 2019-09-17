Buffer3dText = {}
Buffer3dText.Data = {}

Buffer3dText.boundaries = nil
Buffer3dText.last_position = nil
Buffer3dText.waitingForResponse = false

Buffer3dText.area = { ["current"] = nil, ["removed"] = {nil, nil}, ["new"] = {nil, nil} }

function Buffer3dText.getTextByCid(textcid)
	if Buffer3dText.Data[textcid] then return Buffer3dText.Data[textcid] end

	return false
end

function Buffer3dText.getVisibleTexts()
	local list = Buffer3dText.getBufferTexts()
	if not list or #list == 0 then return false end
		
	local texts = {}

	for k,v in ipairs(list) do
		local x, y = getScreenFromWorldPosition(v.position[1], v.position[2], v.position[3])
		if x then
			v["screen_position"] = {["x"]=x, ["y"]=y}
			table.insert(texts, v)
		end 
	end

	if #texts > 0 then return texts
	else return false end
end

function Buffer3dText.getBufferTexts()
	return Buffer3dText.Data
end

function Buffer3dText.sendRequest()
	if Buffer3dText.waitingForResponse then return end

	local x, y, _ = getElementPosition(localPlayer)
	local bound = nil
	local side = {0, 0}
	local wipe = false
	if Buffer3dText.last_position == nil then
		bound = { {x - 50, y + 50, x + 50, y - 50} }
	else
		if math.abs(Buffer3dText.last_position[1]) - math.abs(x) >= 100 or math.abs(Buffer3dText.last_position[2]) - math.abs(y) >= 100 then
			wipe = true

			bound = { {x - 50, y + 50, x + 50, y - 50} }
		else
			if Buffer3dText.last_position[1] ~= x or Buffer3dText.last_position[2] ~= y then
				local old_bound = {Buffer3dText.last_position[1] - 50, Buffer3dText.last_position[2] + 50, Buffer3dText.last_position[1] + 50, Buffer3dText.last_position[2] - 50}

				local tmp = {}
				if x > Buffer3dText.last_position[1] then
					if y > Buffer3dText.last_position[2] then
						tmp[1] = {x - 50, y + 50, Buffer3dText.last_position[1] + 50, Buffer3dText.last_position[2] + 50}
						tmp[2] = {Buffer3dText.last_position[1] + 50, y + 50, x + 50, y - 50}

						side[2] = 1
					elseif y < Buffer3dText.last_position[2] then
						tmp[1] = {x - 50, Buffer3dText.last_position[2] - 50, Buffer3dText.last_position[1] + 50, y - 50}
						tmp[2] = {Buffer3dText.last_position[1] + 50, y + 50, x + 50, y - 50}
						side[2] = -1
					else
						tmp[1] = {Buffer3dText.last_position[1] + 50, Buffer3dText.last_position[2] + 50, x + 50, Buffer3dText.last_position[2] - 50}
						tmp[2] = nil
					end
					side[1] = 1
				elseif x < Buffer3dText.last_position[1] then
					side[1] = -1
					if y > Buffer3dText.last_position[2] then
						tmp[1] = {Buffer3dText.last_position[1] - 50, y + 50, x + 50, Buffer3dText.last_position[2] + 50}
						tmp[2] = {x - 50, y + 50, Buffer3dText.last_position[1] - 50, y - 50}
						side[2] = 1
					elseif y < Buffer3dText.last_position[2] then
						tmp[1] = {x - 50, Buffer3dText.last_position[2] - 50, Buffer3dText.last_position[1] + 50, y - 50}
						tmp[2] = {x - 50, y + 50, Buffer3dText.last_position[1] - 50, y - 50}
						side[2] = -1
					else
						tmp[1] = {x - 50, Buffer3dText.last_position[2] + 50, Buffer3dText.last_position[1] - 50, Buffer3dText.last_position[2] - 50}
						tmp[2] = nil
					end
				else
					tmp[1] = nil
				end


				bound = tmp
			end
		end
	end

	-- reverse bounds
	if bound and (bound[1] ~= nil or bound[2] ~= nil) then
		triggerServerEvent("onClientRequest3dTextChunkData", root, bound)
		Buffer3dText.removeOldChunk(bound, side, wipe)

		Buffer3dText.last_position = {x, y}
		Buffer3dText.waitingForResponse = true
	end
end

function receive3dTextDataChunks(chunk)
	local amount = 0
	if #chunk > 0 then
		for k, v in ipairs(chunk) do
			table.insert(Buffer3dText.Data, v)
			amount = amount + 1
		end
	end

	Buffer3dText.waitingForResponse = false
end

addEvent("onRequested3dTextChunkDataReceived", true)
addEventHandler("onRequested3dTextChunkDataReceived", root, receive3dTextDataChunks)

function receiveCreated3dText(data)
	local x, y, _ = getElementPosition(localPlayer)
	bound = {x - 50, y + 50, x + 50, y - 50}

	if data.position[1] >= bound[1] and data.position[1] <= bound[3] and data.position[2] <= bound[2] and data.position[2] >= bound[4] then
		table.insert(Buffer3dText.Data, data)
	end
end

addEvent("on3dTextCreation", true)
addEventHandler("on3dTextCreation", root, receiveCreated3dText)

function receiveDeleted3dText(id)
	local found = -1
	for k, v in ipairs(Buffer3dText.Data) do
		if v.serverid == id then
			found = k
		end
	end

	if found ~= -1 then 
		table.remove(Buffer3dText.Data, found) 
	end
end

addEvent("on3dTextDeletion", true)
addEventHandler("on3dTextDeletion", root, receiveDeleted3dText)

function Buffer3dText.removeOldChunk(new_bound, side, wipe)
	-- rebound
	wipe = wipe or false
	local old_bound = {}
	local amount = 0
	if wipe then
		Buffer3dText.Data = {}

		old_bound[1] = {Buffer3dText.last_position[1] - 50, Buffer3dText.last_position[2] + 50, Buffer3dText.last_position[1] + 50, Buffer3dText.last_position[2] - 50}
	else
		local x, y = 0, 0
		if side[1] == 1 then x = -100 end
		if side[1] == -1 then x = 100 end
		if side[2] == 1 then y = -100 end
		if side[2] == -1 then y = 100 end

		if new_bound[1] ~= nil then old_bound[1] = {new_bound[1][1], new_bound[1][2] + y, new_bound[1][3], new_bound[1][4] + y} 
		else old_bound[1] = nil end

		if new_bound[2] ~= nil then old_bound[2] = {new_bound[2][1] + x, new_bound[2][2], new_bound[2][3] + x, new_bound[2][4]} 
		else old_bound[2] = nil end

		for k, v in ipairs(Buffer3dText.Data) do
			if (old_bound[1] ~= nil and (v.position[1] >= old_bound[1][1] and v.position[1] <= old_bound[1][3] and v.position[2] <= old_bound[1][2] and v.position[2] >= old_bound[1][4]))
				or (old_bound[2] ~= nil and (v.position[1] >= old_bound[2][1] and v.position[1] <= old_bound[2][3] and v.position[2] <= old_bound[2][2] and v.position[2] >= old_bound[2][4])) then

				table.remove(Buffer3dText.Data, k)
				amount = amount + 1
			end
		end
	end
end

setTimer(Buffer3dText.sendRequest, 500, 0)
