local TweenService = game:GetService("TweenService")

local MidiPlayer = {}

local MidiParser = loadstring(game:GetService("HttpService"):GetAsync("https://raw.githubusercontent.com/mokiros/roblox-midi/main/src/shared/MidiParser.luau"))()
local MidiConstants = shared.CONSTANTS

local _player = {}
_player.__index = _player

function noteToPitch(note: number, transpose: number, fineTuning: number?)
	return ((440 / 32) * math.pow(2, ((note + transpose + ((fineTuning or 0) / 100)) / 12)) / 440) * 8
end

function getNoteIndex(channel: number, note: number)
	return channel * 128 + note + 1
end
local scale = {"C2", "C#2", "D2", "D#2", "E2", "F2", "F#2", "G2", "G#2", "A2", "A#2", "B2", "C3", "C#3", "D3", "D#3", "E3", "F3", "F#3", "G3", "G#3", "A3", "A#3", "B3", "C4", "C#4", "D4", "D#4", "E4", "F4", "F#4", "G4", "G#4", "A4", "A#4", "B4", "C5", "C#5", "D5", "D#5", "E5", "F5", "F#5", "G5", "G#5", "A5", "A#5", "B5", "C6", "C#6", "D6", "D#6", "E6", "F6", "F#6", "G6", "G#6", "A6", "A#6", "B6", "C7", "C#7", "D7", "D#7", "E7", "F7", "F#7", "G7", "G#7", "A7", "A#7", "B7"}

function createNoteSound(note: number, channel: number, patch: number)
	local sound = Instance.new("Sound")
	if channel == 9 then
		local info = MidiConstants.Percussion[note] or MidiConstants.Percussion[31]
		sound.SoundId = info[2].Sound
		if info == MidiConstants.Percussion[31] then
			print(note)
		end
	else
		local info = MidiConstants.Patches[patch] or MidiConstants.Patches[0]
		sound.SoundId = info[3]
	end
	-- local pitch = noteToPitch(note, info[4].Transpose or 0)
	-- if pitch ~= 1 then
	-- 	local pitchEffect = Instance.new("PitchShiftSoundEffect")
	-- 	pitchEffect.Octave = pitch
	-- 	pitchEffect.Parent = sound
	-- end
	-- sound.PlaybackSpeed = pitch
	sound.Name = `{channel} {patch} {note}`
	return sound
end

function _player:_clearSounds()
	for i, sound in self.noteSounds do
		sound:Destroy()
	end
	for i, tween in self.noteTweens do
		tween:Destroy()
	end
	table.clear(self.noteSounds)
	table.clear(self.noteTweens)
end

function _player:_clearChannelSounds(channel: number)
	for note = 0, 127 do
		local index = getNoteIndex(channel, note)
		local sound = self.noteSounds[index]
		if sound then
			sound:Destroy()
		end
		local tween = self.noteTweens[index]
		if tween then
			tween:Destroy()
		end
		self.noteSounds[index] = nil
		self.noteTweens[index] = nil
	end
end

function _player:stopNote(channel: number, note: number, instant: boolean?)
	local index = getNoteIndex(channel, note)
	local prevTween: Tween = self.noteTweens[index]
	if prevTween then
		prevTween:Cancel()
		prevTween:Destroy()
	end
	local sound = self.noteSounds[index]
	local fadeTime = 0.25
	if channel ~= 9 then
		local patch = self.channelInstruments[channel] or 0
		local info = MidiConstants.Patches[patch] or MidiConstants.Patches[0]
		fadeTime = info[4].FadeOut or fadeTime
	end
	if sound then
		if instant == true then
			sound:Stop()
		else
			local tweenInfo = TweenInfo.new(fadeTime)
			local tween = TweenService:Create(sound, tweenInfo, { Volume = 0 })
			tween.Completed:Connect(function(state)
				if state == Enum.PlaybackState.Completed then
					sound:Stop()
				end
			end)
			self.noteTweens[index] = tween
			tween:Play()
		end
	end
end

function _player:playNote(channel: number, note: number, velocity: number)
	warn(note)
	self:stopNote(channel, note, true)
	local noteIndex = getNoteIndex(channel, note)
	local patch = self.channelInstruments[channel] or 0
	local sound = self.noteSounds[noteIndex]
	if not sound then
		sound = createNoteSound(note, channel, patch)
		sound.Parent = self.parent
		self.noteSounds[noteIndex] = sound
	end
	local transpose = 0
	local volume = (velocity / 127) * (self.channelVolumes[channel] or 1)
	local pitch = 1
	if channel ~= 9 then
		local info = MidiConstants.Patches[patch] or MidiConstants.Patches[0]
	      if info.Special then
	     local nn = 1 + (note - 24)
	     if scale[nn] then
	      sound.PlaybackRegionsEnabled = true;
              sound.PlaybackRegion = NumberRange.new(nn, nn+1)
	       game:GetService("Debris"):AddItem(sound, 1)
	        end
		else 
		local set = info[4]
		transpose = set.Transpose or 0
		local pitchWheel = (self.channelPitches[channel] or 0x2000) - 0x2000
		pitch = noteToPitch(note, transpose, -100 - 3500) * (2 ^ ((pitchWheel / 0x2000) / 12))
		if set.Offset then
			sound.TimePosition = set.Offset
		end
		if set.Gain then
			volume += set.Gain
		end
		if set.FadeIn then
			local tweenInfo = TweenInfo.new(set.FadeIn)
			local tween = TweenService:Create(sound, tweenInfo, { Volume = volume })
			volume = 0
			self.noteTweens[noteIndex] = tween
			tween:Play()
		elseif set.Decay then
			local tweenInfo = TweenInfo.new(set.Decay[1])
			local tween = TweenService:Create(sound, tweenInfo, { Volume = set.Decay[2] })
			self.noteTweens[noteIndex] = tween
			tween:Play()
		end
		if set.Loop then
			sound.Looped = true
		else
			sound.Looped = false
		end
		end
	else
		local info = MidiConstants.Percussion[note] or MidiConstants.Percussion[31]
		local data = info[2]
		local set = data.Settings or {}
		volume += set.Volume or 0
		pitch = set.Pitch or pitch
		sound.TimePosition = set.Start or 0
local check = 3 * info[1]
sound.PlaybackRegionsEnabled = true;
sound.PlaybackRegion = NumberRange.new(check, check + 3)
	end
	sound.PlaybackSpeed = pitch
	sound.Volume = volume
local info = MidiConstants.Patches[patch] or MidiConstants.Patches[0]
if info.Special then
		sound:Destroy()
	else
			sound:Play()
	end
end

function _player:reset()
	self.currentTick = 0
	self.currentTempo = 500000
	self:_clearSounds()
	table.clear(self.trackTickBuffers)
	table.clear(self.trackEventIndexes)
	table.clear(self.channelInstruments)
	table.clear(self.channelPitches)
	table.clear(self.channelVolumes)
	table.clear(self.channelSustainPedal)
end

function _player:setTime(time: number)
	self:reset()
	self:update(time, true)
end

function _player:update(deltaTime: number, ignoreNotes: boolean?)
	local deltaTimeMicro = deltaTime * 1_000_000 -- delta time in microseconds
	local singleTickInMicroseconds = self.currentTempo / self.file.division
	local ticks = deltaTimeMicro / singleTickInMicroseconds
	self.currentTick += ticks
	self.parent.Name = self.currentTick
	for trackNumber = 1, self.file.trackCount do
		local track = self.file.tracks[trackNumber]
		local eventIndex = self.trackEventIndexes[trackNumber] or 0
		local tickBuffer = (self.trackTickBuffers[trackNumber] or 0) + ticks
		local nextEvent = track[eventIndex + 1]
		while nextEvent and nextEvent[1] <= tickBuffer do
			local eventType = nextEvent[2]
			if eventType == MidiParser.EventTypes.meta then
				local metaType = nextEvent[3]
				if metaType == 0x51 then -- set tempo
					print(`tempo set to {nextEvent[4]}`)
					self.currentTempo = nextEvent[4]
				elseif metaType == 0x54 then -- SMPTE offset
					error("STUB: SMPTE offset meta event encountered, but not implemented yet")
				elseif metaType == 0x03 then -- track name
					-- noop
				elseif metaType == 0x2F then -- end of track
					-- noop
				else
					warn(`[{trackNumber}] Unknown meta type: {metaType}`)
				end
			elseif eventType == MidiParser.EventTypes.midi then
				local midiType = nextEvent[3]
				local channel = nextEvent[4]
				if (midiType == 0b1001 or midiType == 0b1000) and not ignoreNotes then
					local note = nextEvent[5]
					local velocity = midiType == 0b1000 and 0 or nextEvent[6]
					if velocity == 0 then
						if not self.channelSustainPedal[channel] then
							self:stopNote(channel, note)
						end
					else
						self:playNote(channel, note, velocity)
					end
				elseif midiType == 0b1100 then -- program change, changes the instrument
					local patch = nextEvent[5]
					local patchName = nil
					if channel == 9 then
						patchName = "Percussion"
					else
						local info = MidiConstants.Patches[patch]
						if info then
							patchName = info[2]
						end
					end
					print(`[{trackNumber}] Channel {channel} switched to {patchName or `[MISSING INSTRUMENT {patch}]`}`)
					self.channelInstruments[channel] = patch
					self:_clearChannelSounds(channel)
				elseif midiType == 0b1110 then -- pitch wheel change
					local pitch = bit32.lshift(nextEvent[5], 7) + nextEvent[6]
					self.channelPitches[channel] = pitch
				elseif midiType == 0b1011 then -- control change
					local controller = nextEvent[5]
					local value = nextEvent[6]
					if controller == 7 then -- channel volume
						self.channelVolumes[channel] = value / 127
					elseif controller == 64 then -- damper/sustain pedal on/off
						self.channelSustainPedal[channel] = value >= 64
					elseif controller == 10 then -- Pan control for left/right balance
						-- noop, can't control left/right balance
					elseif controller == 6 or controller == 100 or controller == 101 then -- RPN parameters
						-- noop, don't really know what to do with this
					elseif controller == 0 or controller == 32 then -- bank select
						-- noop, don't have any other instruments
					elseif controller == 91 then -- Effect 1 depth, controls reverb
						warn(`[{trackNumber}] STUB: controller 91 (reverb) encountered with value {value}`)
					elseif controller == 1 then -- Modulation wheel
						warn(`[{trackNumber}] STUB: controller 1 (modulation wheel) encountered with value {value}`)
					else
						warn(`[{trackNumber}] Unknown controller number: {controller}`)
					end
				else
					warn(`[{trackNumber}] Unknown midi type: {midiType}`)
				end
			end
			tickBuffer -= nextEvent[1]
			eventIndex += 1
			nextEvent = track[eventIndex + 1]
		end
		self.trackEventIndexes[trackNumber] = eventIndex
		self.trackTickBuffers[trackNumber] = tickBuffer
	end
end

function MidiPlayer.LoadFile(file: MidiParser.MidiFile, parent: Instance)
	local player = setmetatable({
		file = file,
		parent = parent,
		currentTempo = 500000,
		currentTick = 0,
		trackTickBuffers = table.create(file.trackCount),
		trackEventIndexes = table.create(file.trackCount),
		channelInstruments = table.create(16),
		channelPitches = table.create(16),
		channelVolumes = table.create(16),
		channelSustainPedal = table.create(16),
		noteSounds = table.create(16 * 128),
		noteTweens = table.create(16 * 128),
	}, _player)
	player:reset()
	return player
end

return MidiPlayer
