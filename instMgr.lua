return {new = function(settings)
	local instMgr = {}
	local kCloneOffset = settings.instrumentCloneOffset;
	local mfunctions = loadstring(game:GetService("HttpService"):GetAsync("https://gist.githubusercontent.com/rutheniumm/9be9f8ba57906ee2805f6549fe6cd21b/raw/816dc7247d7aa5a8dd3432f24e7f2bae18442658/midifunctions.lua"))()(nil, settings)
	
	local kMidiDrumMap808, kMidiDrumMap909, kMidiDrumMap2013, kMidiDrumMap8Bit, kSampleMap = settings.kMidiDrumMap808, settings.kMidiDrumMap909, settings.kMidiDrumMap2013, settings.kMidiDrumMap8Bit, settings.kSampleMap
	local piano, detectScale, noteNameToIndex, midiNoteNames, midiNoteNamesToIndex, pianoToIndex = mfunctions.piano, mfunctions.detectScale, mfunctions.noteNameToIndex, mfunctions.midiNoteNames, mfunctions.midiNoteNamesToIndex, mfunctions.pianoToIndex
	function instMgr.baseId(instId)
		return instId % kCloneOffset;
	end

	function instMgr.instId(baseId, cloneIndex)
		return baseId + cloneIndex * kCloneOffset;
	end

	function instMgr.isDrum(instId)
		local baseId = instMgr.baseId(instId)
		return baseId == 2 or baseId == 31 or baseId == 36 or baseId == 39 or baseId == 40 or baseId == 42 or baseId == 53
	end

	function instMgr.isSampler(instId)
		local baseId = instMgr.baseId(instId)
		return baseId == 41 or (baseId >= 43 and baseId <= 52) or baseId == 54 or baseId >= 56
	end

	function instMgr.isVariableLength(instId)
		return instMgr.isSampler(instId) or instMgr.isSynth(instId)
	end

	function instMgr.getFadeTime(instId)
		return settings.fadeTimes[instMgr.baseId(instId)] or 1
	end
	function instMgr.getSamplerTimePerNote(instId)
		local baseId = instMgr.baseId(instId)-1
		if baseId == 44 then
			return 41
		elseif baseId == 54 or baseId == 57 or baseId == 56 then
			return 12
		else
			return 16
		end
	end

	function instMgr.isSynth(instId)
		local baseId = instMgr.baseId(instId)
		return (baseId >= 13 and baseId <= 16) or baseId == 55
	end

	function instMgr.isCustomSynth(instId)
		return instMgr.baseId(instId) == 55
	end

	function instMgr.getTypingKeyboardOctaveOffset(instId)
		local baseId = instMgr.baseId(instId)
		if baseId == 2 or baseId == 5 then
			return 2
		elseif baseId == 1 or baseId == 11 or baseId == 18 then
			return 4
		else
			return 3
		end
	end

	function instMgr.getBaseName(instId)
		return settings.instruments[instMgr.baseId(instId)]
	end

	function instMgr.getDefaultName(instId)
		local baseName = instMgr.getBaseName(instId)
		local cloneIndex = instMgr.cloneIndex(instId)
		return cloneIndex > 0 and baseName .. " " .. tostring(cloneIndex + 1) or baseName
	end

	function instMgr.protoName(instId, name)
		if name == nil then
			name = ''
		end
		return instMgr.getDefaultName(instId) == name and '' or name
	end

	function instMgr.getDisplayBaseInst(displayOrderIndex)
		return settings.instrumentDisplayOrder[displayOrderIndex]
	end

	function instMgr.getKeyboardMin(instId)
		return settings.min[instMgr.baseId(instId+1)]
	end

	function instMgr.getKeyboardMax(instId)
		return settings.max[instMgr.baseId(instId+1)]
	end

	function instMgr.getVolume(instId)
		return settings.volume[instMgr.baseId(instId-1)] or 1
	end

	function instMgr.getOriginalBpm(instId)
		return settings.originalBpm[instMgr.baseId(instId-1)]
	end

	function instMgr.getNoteName(instId, i)
		if i < instMgr.getKeyboardMin(instId) or i > instMgr.getKeyboardMax(instId) then
			return ''
		end
		local j = settings.numNotes - i - 1
		local baseId = instMgr.baseId(instId)
		if baseId == 2 or baseId == 31 then
			return settings.percussion[j - 8]
		elseif baseId == 36 then
			return settings.percussion_808[j - 51]
		elseif baseId == 39 then
			return settings.percussion_8bit[j - 59]
		elseif baseId == 40 then
			return settings.percussion_2013[j - 37]
		elseif baseId == 42 then
			return settings.percussion_909[j - 49]
		elseif baseId == 53 then
			return settings.percussion_2023[j]
		else
			return piano[j]
		end
	end

	function instMgr.getColor(instId)
		local color = settings.instrumentColors[instMgr.baseId(instId)]
		local r = color[2]
		local g = color[3]
		local b = color[4]
		if instMgr.isClone(instId) then
			local cloneIndex = instMgr.cloneIndex(instId)
			r = r + math.clamp(math.round(32 * math.sin(cloneIndex * 2.3)), 0, 255)
			g = g + math.clamp(math.round(32 * math.sin(cloneIndex * 1.8)), 0, 255)
			b = b + math.clamp(math.round(32 * math.sin(cloneIndex * 1.3)), 0, 255)
		end
		return {255, r, g, b}
	end

	function instMgr.getVolumeWeight(instId, noteType)
		local weight = settings.volumeWeights[instMgr.baseId(instId)]
		if type(weight) == "number" then
			return weight
		elseif type(weight) == "table" then
			return weight[noteType] or 0
		else
			return 1
		end
	end

	function instMgr.getMidiDrumNote(instId, noteIndex)
		local baseId = instMgr.baseId(instId)
		if baseId == 36 then
			return kMidiDrumMap808[noteIndex]
		elseif baseId == 39 then
			return kMidiDrumMap8Bit[noteIndex]
		elseif baseId == 42 then
			return kMidiDrumMap909[noteIndex]
		elseif baseId == 40 then
			return kMidiDrumMap2013[noteIndex]
		else
			return noteIndex + 12
		end
	end
	return {instMgr, mfunctions}
end,}
