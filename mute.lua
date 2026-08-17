if string.lower(RequiredScript) == "lib/managers/localizationmanager" then
	_G.MuteSounds = _G.MuteSounds or {}
	MuteSounds._mod_path = MuteSounds._mod_path or ModPath
	MuteSounds._setting_path = ModPath .. "save.json"
	MuteSounds.settings = MuteSounds.settings or {}
	MuteSounds.vc_active = false
	
	function MuteSounds:Save()
		local file = io.open(self._setting_path, "w+")
		if file then
			file:write(json.encode(self.settings))
			file:close()
		end
	end

	function MuteSounds:Load()
		local file = io.open(self._setting_path, "r")
		if file then
			for k, v in pairs(json.decode(file:read("*all")) or {}) do
				self.settings[k] = v
			end
			file:close()
		else
			self.settings = {
				mute_volume = 15
			}
			self:Save()
		end
	end

	Hooks:Add("MenuManagerInitialize", "MenuManagerInitialize_MuteSounds", function(...)
		MuteSounds:Load()
		
		MenuCallbackHandler.MS_mute_volume_callback = function(self, item)
			MuteSounds.settings.mute_volume = tonumber(item:value()) or 15
			MuteSounds:Save()
		end
		
		MenuHelper:LoadFromJsonFile(MuteSounds._mod_path .. "options.json", MuteSounds, MuteSounds.settings)
	end)

	Hooks:Add("LocalizationManagerPostInit", "MuteSounds_loc", function(...)				
		LocalizationManager:add_localized_strings({
			menu_MS_name = "Mute sounds while the voice chat speaking",
			MS_mute_volume_title = "Mute volume",
		})
			
		if Idstring("russian"):key() == SystemInfo:language():key() then
			LocalizationManager:add_localized_strings({
				MS_mute_volume_title = "Уровень приглушения",
			})
		end
	end)
elseif string.lower(RequiredScript) == "lib/network/matchmaking/networkvoicechatsteam" then
	local function mute()
		local sfx = managers.user:get_setting("sfx_volume")
		local music = managers.user:get_setting("music_volume")
		local mute_volume = _G.MuteSounds.settings.mute_volume / 100 or 1
		
		SoundDevice:set_rtpc("option_sfx_volume", sfx * mute_volume)
		SoundDevice:set_rtpc("option_music_volume", music * mute_volume)
	end

	Hooks:PostHook(NetworkVoiceChatSTEAM, "update", "MuteSounds_mute_volumes", function(self)
		local t = Application:time()
		local playing = self.handler:get_voice_receivers_playing()
		for id, pl in pairs(playing) do
			local peer_talk = self._users_talking[id]
			if self._enabled and peer_talk ~= nil and peer_talk.time ~= nil and t < peer_talk.time + 0.5 then
				mute()
			end
		end
	end)
	
	Hooks:PostHook(NetworkVoiceChatSTEAM, "destroy_voice", "MuteSounds_reset_volumes", function(self, disconnected)
		SoundDevice:set_rtpc("option_sfx_volume", managers.user:get_setting("sfx_volume"))
		SoundDevice:set_rtpc("option_music_volume", managers.user:get_setting("music_volume"))
	end)
end