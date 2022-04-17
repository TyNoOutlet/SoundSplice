local module = {}

local DSS = game:GetService("DataStoreService")
local checkpoints = DSS:GetDataStore("CheckpointStore")
local nameRefs = DSS:GetDataStore("NameRefStore")

module.Checkpoints = {}
module.NameRefs = {}

function module:Calibrate(sound, stops, waitLength)
	sound:Play()
	task.spawn(function()
		local startEmpty, finishEmpty
		while true do
			repeat task.wait() until sound.Playing == true
			task.wait()
			self.Checkpoints[sound.Name] = {}
			while sound.Playing == true do
				task.wait()
				print(sound.PlaybackLoudness, sound.Playing)
				if sound.PlaybackLoudness <= stops then
					print("quiet")
					startEmpty = sound.TimePosition
					repeat task.wait() until sound.PlaybackLoudness > stops or sound.Playing == false
					finishEmpty = sound.TimePosition
					print("loud")
					if finishEmpty - startEmpty >= waitLength then
						if #self.Checkpoints[sound.Name] == 0 then
							self.Checkpoints[sound.Name][1] = {}
							local item = self.Checkpoints[sound.Name][1]
							table.insert(item, finishEmpty - 0.025)
							warn("inserted")
						else
							self.Checkpoints[sound.Name][#self.Checkpoints[sound.Name] + 1] = {}
							local item = self.Checkpoints[sound.Name][#self.Checkpoints[sound.Name]]
							table.insert(self.Checkpoints[sound.Name][#self.Checkpoints[sound.Name] - 1], startEmpty + 0.025)
							table.insert(item, finishEmpty - 0.025)
							warn("inserted")
						end
					end
				end
			end
			print(self.Checkpoints[sound.Name])
			for i, v in ipairs(self.Checkpoints[sound.Name]) do
				v[1] = tostring(v[1])
				v[1] = string.sub(v[1], 1, 4)
				v[1]= tonumber(v[1])
				v[2] = tostring(v[2])
				v[2] = string.sub(v[2], 1, 4)
				v[2]= tonumber(v[2])
			end
			local success, err = pcall(function()
				return checkpoints:SetAsync(sound.Name, self.Checkpoints[sound.Name])
			end)
			if not success then warn("SoundSplice | " .. err) end
			break
		end
	end)
end

function module:PlaySfx(sound, sfx)
	if not self.Checkpoints[sound.Name] then
		local success, data = pcall(function()
			return checkpoints:GetAsync(sound.Name)
		end)
		if success then
			self.Checkpoints[sound.Name] = data
		else
			warn("SoundSplice | No item with that name found. Did you calibrate the sound with :Calibrate() first? Check the docs for usage info.")
			return
		end
	end
	if not self.NameRefs[sound.Name] then
		local success, data = pcall(function()
			return nameRefs:GetAsync(sound.Name)
		end)
		if success then
			self.NameRefs[sound.Name] = data
		else
			warn("SoundSplice | No item with that name found. Did you name the SFX? Check the docs for usage info.")
			return
		end
	end
	if typeof(sfx) == "number" then
		if self.Checkpoints[sound.Name][sfx] then
			sound.TimePosition = self.Checkpoints[sound.Name][sfx][1]
			sound:Play()
			repeat task.wait() until sound.TimePosition >= self.Checkpoints[sound.Name][sfx][2]
			sound:Stop()
		end
	else
		if table.find(self.NameRefs[sound.Name], sfx) then
			sound.TimePosition = self.Checkpoints[sound.Name][table.find(self.NameRefs[sound.Name], sfx)][1]
			sound:Play()
			repeat task.wait() until sound.TimePosition >= self.Checkpoints[sound.Name][table.find(self.NameRefs[sound.Name], sfx)][2]
			sound:Stop()
		end
	end
end

function module:EraseSfx(sound)
	if self.Checkpoints[sound.Name] then
		self.Checkpoints[sound.Name] = nil
	end
	local success, data = pcall(function()
		return checkpoints:RemoveAsync(sound.Name)
	end)
	if not success then 
		warn("SoundSplice | " .. data)
	else
		warn("SoundSplice | Successfully erased!")
	end
end

function module:GetSoundList(sound)
	if not self.Checkpoints[sound.Name] then
		local success, data = pcall(function()
			return checkpoints:GetAsync(sound.Name)
		end)
		if success then
			self.Checkpoints[sound.Name] = data
		else
			warn("SoundSplice | No item with that name found. Did you calibrate the sound with :Calibrate() first? Check the docs for usage info.")
			return
		end
	end
	print("\n SoundSplice | List of SFX in " .. sound.Name)
	for i, v in ipairs(self.Checkpoints[sound.Name]) do
		if v[2] then
			print(tostring(i) .. " | Start time: " .. v[1] .. " | Finish time: " .. v[2])
		else
			print(tostring(i) .. " | Start time: " .. v[1])
		end
	end
end

function module:NameSfx(sound, sfx, name)
	if not self.Checkpoints[sound.Name] then
		local success, data = pcall(function()
			return checkpoints:GetAsync(sound.Name)
		end)
		if success then
			self.Checkpoints[sound.Name] = data
		else
			warn("SoundSplice | No item with that name found. Did you calibrate the sound with :Calibrate() first? Check the docs for usage info.")
			return
		end
	end
	if not self.NameRefs[sound.Name] then
		local success, data = pcall(function()
			return nameRefs:GetAsync(sound.Name) or {}
		end)
		if success then
			self.NameRefs[sound.Name] = data
		else
			warn("SoundSplice | No item with that name found. Did you calibrate the sound with :Calibrate() first? Check the docs for usage info.")
			return
		end
	end
	if not self.NameRefs[sound.Name][1] then
		for i, v in ipairs(self.Checkpoints[sound.Name]) do
			self.NameRefs[sound.Name][i] = ""
		end
	end
	if self.NameRefs[sound.Name][sfx] then
		self.NameRefs[sound.Name][sfx] = name
	end
	local success, err = pcall(function()
		return nameRefs:SetAsync(sound.Name, self.NameRefs[sound.Name])
	end)
	if not success then warn("SoundSplice | " .. err) end
end

return module
