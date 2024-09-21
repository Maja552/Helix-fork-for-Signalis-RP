
local padding = ScreenScale(32)

-- create character panel
DEFINE_BASECLASS("ixCharMenuPanel")
local PANEL = {}

local descriptionPage = 1
local classDescription = ''
local classStats = nil
local classDescriptionText = nil

local nextPageTurn = 0

function PANEL:Init()
	local parent = self:GetParent()
	local halfWidth = parent:GetWide() * 0.5 - (padding * 2)
	local thirdWidth = parent:GetWide() * 0.33 - (padding * 2)
	local halfHeight = parent:GetTall() * 0.5 - (padding * 2)
	local modelFOV = (ScrW() > ScrH() * 1.8) and 90 or 68

	self:ResetPayload(true)

	self.factionButtons = {}
	self.classButtons = {}
	self.repopulatePanels = {}

	-- faction selection subpanel
	self.factionPanel = self:AddSubpanel("faction", true)
	self.factionPanel:SetTitle("chooseFaction")
	self.factionPanel.OnSetActive = function()
		-- if we only have one faction, we are always selecting that one so we can skip to the description section
		if (#self.factionButtons == 1) then
			self:SetActiveSubpanel("class", 0)
		end
	end

	local modelFactionList = self.factionPanel:Add("Panel")
	modelFactionList:Dock(RIGHT)
	modelFactionList:SetSize(halfWidth + padding * 2, halfHeight)

	local factionProceed = modelFactionList:Add("ixMenuButton")
	factionProceed:SetText("proceed")
	factionProceed:SetContentAlignment(6)
	factionProceed:Dock(BOTTOM)
	factionProceed:SizeToContents()
	factionProceed.DoClick = function()
		self.progress:IncrementProgress()

		if IsValid(self.statsPanel) then
			self.statsPanel.ResetParams(self.statsPanel)
		end

		local faction = ix.faction.indices[self.payload["faction"]]
		self.classPanel.title:SetTextColor(faction.color or color_white)

		self:Populate(true)
		if (#self.classButtons < 2) then
			self:SetActiveSubpanel("description")
			self.progress:IncrementProgress()
		else
			self:SetActiveSubpanel("class")
		end
	end

	local factionBack = self.factionPanel:Add("ixMenuButton")
	factionBack:SetText("return")
	factionBack:SizeToContents()
	factionBack:DockMargin(0, 80, 0, 0)
	factionBack:Dock(BOTTOM)
	factionBack.DoClick = function()
		self.payload["class"] = nil
		self.payload["model"] = nil
		self.classButtons = {}

		self.progress:DecrementProgress()

		self:SetActiveSubpanel("faction", 0)
		self:SlideDown()

		parent.mainPanel:Undim()
	end

	self.factionButtonsPanel = self.factionPanel:Add("ixCharMenuButtonList")
	self.factionButtonsPanel:SetWide(halfWidth)
	self.factionButtonsPanel:Dock(BOTTOM)

	self.classPanel = self:AddSubpanel("class", true)
	self.classPanel:SetTitle("CHOOSE A CLASS")
	self.classPanel.OnSetActive = function()
		-- if we only have one class, we are always selecting that one so we can skip to the description section
		if (#self.classButtons == 1) then
			self:SetActiveSubpanel("description", 0)
		end
	end

	local modelClassList = self.classPanel:Add("Panel")
	modelClassList:Dock(RIGHT)
	modelClassList:SetSize(thirdWidth + padding * 2, halfHeight)

	local statsPanelWidth = thirdWidth + padding * 2

	self.statsPanel = self.classPanel:Add("Panel")
	self.statsPanel:Dock(RIGHT)
	self.statsPanel:SetWidth(statsPanelWidth)
	self.statsPanel.spaceBetween = 38
	self.statsPanel.ResetParams = function(self)
		descriptionPage = 1
		classDescription = ''
		classStats = nil
		self.stats = nil
		self.statsY = 0
		if IsValid(classDescriptionText) then
			classDescriptionText:SetText("")
		end
	end
	self.statsPanel.statsY = 0
	self.statsPanel.stats = nil
	self.statsPanel:SetMouseInputEnabled(true)
	self.statsPanel.SetParams = function(self, stats)
		local stats = classStats
		if stats then
			self.stats = {}
			self.statsY = 0
			for k,v in pairs(stats) do
				local name = string.gsub(k, "_", " ")
				name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
				self.stats[k] = {name = name, value = v, y = self.statsY}
				self.statsY = self.statsY + self.spaceBetween
			end
			self.statsY = self.statsY + self.spaceBetween
		end

		if classDescription and classDescription[descriptionPage] then
			classDescriptionText:SetText(classDescription[descriptionPage])
		end
	end
	self.statsPanel.Paint = function(self, w, h)
		if self.stats then
			for k,v in pairs(self.stats) do
				draw.DrawText(v.name .. ": " .. v.value, "ixMenuButtonFontSmall", 8, v.y, color_white, TEXT_ALIGN_LEFT)
			end
		end
	end

	classDescriptionText = self.statsPanel:Add("DTextEntry")
	classDescriptionText:SetMultiline(true)
	classDescriptionText:SetEditable(false)
	classDescriptionText:SetDisabled(true)
	classDescriptionText:SetFont("ixMenuButtonFontSmall")
	classDescriptionText:SetPaintBackground(false)
	classDescriptionText:SetTextColor(color_white)
	classDescriptionText:SetHeight(ScrH() * 0.4)
	classDescriptionText:Dock(BOTTOM)
	classDescriptionText:SetMouseInputEnabled(true)

	local cDw, cDh = classDescriptionText:GetSize()
	local buttonSize = 40

	local pageLeftButton = classDescriptionText:Add("DButton")
	pageLeftButton:SetText("")
	pageLeftButton:SetPos(16, cDh - buttonSize)
	pageLeftButton:SetSize(buttonSize, buttonSize)
	pageLeftButton:SetMouseInputEnabled(true)
	pageLeftButton.Paint = function(this, w, h)
		if classDescription[descriptionPage - 1] then
			draw.TextShadow({
				text = "<",
				font = "SignalisDocumentsFontBig",
				pos = {w / 2, h / 2},
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_CENTER,
				color = color_white
			}, 1, 255)
		end
	end
	pageLeftButton.DoClick = function()
		if nextPageTurn < CurTime() and descriptionPage > 1 and classDescription[descriptionPage - 1] then
			descriptionPage = descriptionPage - 1
			classDescriptionText:SetText(classDescription[descriptionPage])
			nextPageTurn = CurTime() + 0.3
		end
	end

	local pageRightButton = classDescriptionText:Add("DButton")
	pageRightButton:SetText("")
	pageRightButton:SetPos(statsPanelWidth - buttonSize - 16, cDh - buttonSize)
	pageRightButton:SetSize(buttonSize, buttonSize)
	pageRightButton:SetMouseInputEnabled(true)
	pageRightButton.Paint = function(this, w, h)
		if classDescription[descriptionPage + 1] then
			draw.TextShadow({
				text = ">",
				font = "SignalisDocumentsFontBig",
				pos = {w / 2, h / 2},
				xalign = TEXT_ALIGN_CENTER,
				yalign = TEXT_ALIGN_CENTER,
				color = color_white
			}, 1, 255)
		end
	end
	pageRightButton.DoClick = function()
		if nextPageTurn < CurTime() and classDescription[descriptionPage + 1] then
			descriptionPage = descriptionPage + 1
			classDescriptionText:SetText(classDescription[descriptionPage])
			nextPageTurn = CurTime() + 0.3
		end
	end

	self.classProceed = modelClassList:Add("ixMenuButton")
	self.classProceed:SetText("proceed")
	self.classProceed:SetContentAlignment(6)
	self.classProceed:SizeToContents()
	self.classProceed:Dock(BOTTOM)
	self.classProceed:SetWide(halfWidth)
	self.classProceed:SetTextColor(Color(100,100,100))
	self.classProceed.DoClick = function()
		if self.payload["model"] then
			self.progress:IncrementProgress()

			self:Populate()
			self:SetActiveSubpanel("description")
		end
	end

	local classBack = self.classPanel:Add("ixMenuButton")
	classBack:SetText("return")
	classBack:SizeToContents()
	classBack:DockMargin(0, 80, 0, 0)
	classBack:Dock(BOTTOM)
	classBack:SetWide(halfWidth)
	classBack.DoClick = function()
		self.payload["class"] = nil
		self.payload["model"] = nil
		
		if IsValid(self.statsPanel) then
			self.statsPanel.ResetParams(self.statsPanel)
		end

		self.progress:DecrementProgress()

		self:Populate()
		self:SetActiveSubpanel("class", 0)
		self:SlideDown()

		parent.mainPanel:Undim()
	end

	self.classButtonsPanel = self.classPanel:Add("ixCharMenuButtonList")
	self.classButtonsPanel:SetWide(thirdWidth)
	self.classButtonsPanel:Dock(LEFT)
	--self.classButtonsPanel.Paint = function(self, w, h) draw.RoundedBox(0, 0, 0, w, h, Color(0,255,0)) end

	self.classModel = modelClassList:Add("ixModelPanel")
	self.classModel:Dock(FILL)
	self.classModel:SetModel("models/error.mdl")
	self.classModel:SetFOV(modelFOV)
	self.classModel.PaintModel = self.classModel.Paint

	-- character customization subpanel
	self.description = self:AddSubpanel("description")
	self.description:SetTitle("chooseDescription")

	local descriptionModelList = self.description:Add("Panel")
	descriptionModelList:Dock(LEFT)
	descriptionModelList:SetSize(halfWidth, halfHeight)

	local descriptionBack = descriptionModelList:Add("ixMenuButton")
	descriptionBack:SetText("return")
	descriptionBack:SetContentAlignment(4)
	descriptionBack:SizeToContents()
	descriptionBack:Dock(BOTTOM)
	descriptionBack.DoClick = function()
		self.payload["class"] = nil
		self.payload["model"] = nil

		descriptionPage = 1
		classDescription = ''
		classStats = nil

		self.progress:DecrementProgress()

		if (#self.classButtons < 2) then
			self.progress:DecrementProgress()
		end

		if (#self.factionButtons == 1) then
			factionBack:DoClick()
		else
			self:SetActiveSubpanel("faction")
		end
	end

	self.descriptionModel = descriptionModelList:Add("ixModelPanel")
	self.descriptionModel:Dock(FILL)
	self.descriptionModel:SetModel(self.classModel:GetModel())
	self.descriptionModel:SetFOV(modelFOV - 13)
	self.descriptionModel.PaintModel = self.descriptionModel.Paint

	self.descriptionPanel = self.description:Add("Panel")
	self.descriptionPanel:SetWide(halfWidth + padding * 2)
	self.descriptionPanel:Dock(RIGHT)

	local descriptionProceed = self.descriptionPanel:Add("ixMenuButton")
	descriptionProceed:SetText("proceed")
	descriptionProceed:SetContentAlignment(6)
	descriptionProceed:SizeToContents()
	descriptionProceed:Dock(BOTTOM)
	descriptionProceed.DoClick = function()
		if (self:VerifyProgression("description")) then
			-- there are no panels on the attributes section other than the create button, so we can just create the character
			if (#self.attributesPanel:GetChildren() < 2) then
				self:SendPayload()
				return
			end

			self.progress:IncrementProgress()
			self:SetActiveSubpanel("attributes")
		end
	end

	self.attributes = self:AddSubpanel("attributes")
	self.attributes:SetTitle("chooseSkills")

	local attributesModelList = self.attributes:Add("Panel")
	attributesModelList:Dock(LEFT)
	attributesModelList:SetSize(halfWidth, halfHeight)

	local attributesBack = attributesModelList:Add("ixMenuButton")
	attributesBack:SetText("return")
	attributesBack:SetContentAlignment(4)
	attributesBack:SizeToContents()
	attributesBack:Dock(BOTTOM)
	attributesBack.DoClick = function()
		self.progress:DecrementProgress()
		self:SetActiveSubpanel("description")
	end

	self.attributesModel = attributesModelList:Add("ixModelPanel")
	self.attributesModel:Dock(FILL)
	self.attributesModel:SetModel(self.classModel:GetModel())
	self.attributesModel:SetFOV(modelFOV - 13)
	self.attributesModel.PaintModel = self.attributesModel.Paint

	self.attributesPanel = self.attributes:Add("Panel")
	self.attributesPanel:SetWide(halfWidth + padding * 2)
	self.attributesPanel:Dock(RIGHT)

	local create = self.attributesPanel:Add("ixMenuButton")
	create:SetText("finish")
	create:SetContentAlignment(6)
	create:SizeToContents()
	create:Dock(BOTTOM)
	create.DoClick = function()
		self:SendPayload()
	end

	-- creation progress panel
	self.progress = self:Add("ixSegmentedProgress")
	self.progress:SetBarColor(ix.config.Get("color"))
	self.progress:SetSize(parent:GetWide(), 0)
	self.progress:SizeToContents()
	self.progress:SetPos(0, parent:GetTall() - self.progress:GetTall())

	-- setup payload hooks
	self:AddPayloadHook("model", function(value)
		local class = ix.class.list[self.payload.class]

		if (class) then
			local model = class:GetModels(LocalPlayer())[value]

			self.classModel:SetModel(model)
			self.descriptionModel:SetModel(model)
			self.attributesModel:SetModel(model)
		end
	end)

	-- setup character creation hooks
	net.Receive("ixCharacterAuthed", function()
		timer.Remove("ixCharacterCreateTimeout")
		self.awaitingResponse = false

		local id = net.ReadUInt(32)
		local indices = net.ReadUInt(6)
		local charList = {}

		for _ = 1, indices do
			charList[#charList + 1] = net.ReadUInt(32)
		end

		ix.characters = charList

		self:SlideDown()

		if (!IsValid(self) or !IsValid(parent)) then
			return
		end

		if (LocalPlayer():GetCharacter()) then
			parent.mainPanel:Undim()
			parent:ShowNotice(2, L("charCreated"))
		elseif (id) then
			self.bMenuShouldClose = true

			net.Start("ixCharacterChoose")
				net.WriteUInt(id, 32)
			net.SendToServer()
		else
			self:SlideDown()
		end
	end)

	net.Receive("ixCharacterAuthFailed", function()
		timer.Remove("ixCharacterCreateTimeout")
		self.awaitingResponse = false

		local fault = net.ReadString()
		local args = net.ReadTable()

		self:SlideDown()

		parent.mainPanel:Undim()
		parent:ShowNotice(3, L(fault, unpack(args)))
	end)
end

function PANEL:SendPayload()
	if (self.awaitingResponse or !self:VerifyProgression()) then
		return
	end

	self.awaitingResponse = true

	timer.Create("ixCharacterCreateTimeout", 10, 1, function()
		if (IsValid(self) and self.awaitingResponse) then
			local parent = self:GetParent()

			self.awaitingResponse = false
			self:SlideDown()

			parent.mainPanel:Undim()
			parent:ShowNotice(3, L("unknownError"))
		end
	end)

	self.payload:Prepare()

	net.Start("ixCharacterCreate")
	net.WriteUInt(table.Count(self.payload), 8)

	for k, v in pairs(self.payload) do
		net.WriteString(k)
		net.WriteType(v)
	end

	net.SendToServer()
end

function PANEL:OnSlideUp()
	self:ResetPayload()
	self:Populate()
	self.progress:SetProgress(1)

	-- the faction subpanel will skip to next subpanel if there is only one faction to choose from,
	-- so we don't have to worry about it here
	self:SetActiveSubpanel("faction", 0)
end

function PANEL:OnSlideDown()
end

function PANEL:ResetPayload(bWithHooks)
	if (bWithHooks) then
		self.hooks = {}
	end

	self.payload = {}

	-- TODO: eh..
	function self.payload.Set(payload, key, value)
		self:SetPayload(key, value)
	end

	function self.payload.AddHook(payload, key, callback)
		self:AddPayloadHook(key, callback)
	end

	function self.payload.Prepare(payload)
		self.payload.Set = nil
		self.payload.AddHook = nil
		self.payload.Prepare = nil
	end
end

function PANEL:SetPayload(key, value)
	self.payload[key] = value
	self:RunPayloadHook(key, value)
end

function PANEL:AddPayloadHook(key, callback)
	if (!self.hooks[key]) then
		self.hooks[key] = {}
	end

	self.hooks[key][#self.hooks[key] + 1] = callback
end

function PANEL:RunPayloadHook(key, value)
	local hooks = self.hooks[key] or {}

	for _, v in ipairs(hooks) do
		v(value)
	end
end

function PANEL:GetContainerPanel(name)
	-- TODO: yuck
	if (name == "description") then
		return self.descriptionPanel
		
	elseif (name == "attributes") then
		return self.attributesPanel
	end

	return self.descriptionPanel
end

function PANEL:AttachCleanup(panel)
	self.repopulatePanels[#self.repopulatePanels + 1] = panel
end

function PANEL:populateClassButtons()
	for _, v in pairs(self.classButtons) do
		if (IsValid(v)) then
			v:Remove()
		end
	end

	self.classButtons = {}

	for _, v in SortedPairs(ix.class.list) do
		if v.faction == self.payload["faction"] && ix.class.HasClassWhitelist(v.index) then
			local button = self.classButtonsPanel:Add("ixMenuSelectionButton")
			local faction = ix.faction.indices[self.payload["faction"]]
			button:SetBackgroundColor(faction.color or color_white)
			button:SetText(L(v.name):utf8upper())
			button:SizeToContents()
			button:SetButtonList(self.classButtons)
			button.class = v.index
			button.OnSelected = function(panel)
				local class = ix.class.list[panel.class]
				local models = class:GetModels(LocalPlayer())

				classStats = {
					health = class.health,
					physical_damage_taken = class.physical_damage_taken,
					bullet_damage_taken = class.bullet_damage_taken,
					mental_strength = class.mental_strength,
					hunger = class.hunger,
					thirst = class.thirst,
					speed = class.speed,
					jump_power = class.jump_power,
					max_stamina = class.max_stamina,
				}

				descriptionPage = 1
				classDescription = class.description
				self.statsPanel.SetParams(self.statsPanel, classStats)

				self.payload:Set("class", panel.class)
				self.payload:Set("model", math.random(1, #models))
				self.classProceed:SetTextColor(color_white)
			end
		end
	end
end

function PANEL:PopulateSegments()
	self.progress.progress = 0
	self.progress.segments = {}

	-- setup progress bar segments
	if (#self.factionButtons > 1) then
		self.progress:AddSegment("@faction")
	end
	
	--if (#self.classButtons > 1) then
		self.progress:AddSegment("@class")
	--end

	self.progress:AddSegment("@description")

	--if (#self.attributesPanel:GetChildren() > 1) then
		--self.progress:AddSegment("@skills")
	--end

	-- we don't need to show the progress bar if there's only one segment
	if (#self.progress:GetSegments() == 1) then
		self.progress:SetVisible(false)
	end
end

function PANEL:Populate(redo)
	if (!self.bInitialPopulate or redo) then
		-- setup buttons for the faction panel
		-- TODO: make this a bit less janky
		local lastSelected

		for _, v in pairs(self.factionButtons) do
			if (v:GetSelected()) then
				lastSelected = v.faction
			end

			if (IsValid(v)) then
				v:Remove()
			end
		end

		self.factionButtons = {}

		for _, v in SortedPairs(ix.faction.teams) do
			if (ix.faction.HasWhitelist(v.index)) then
				local num = 0
				for _, v2 in SortedPairs(ix.class.list) do
					if v2.faction == v.index && ix.class.HasClassWhitelist(v2.index) then
						num = num + 1
					end
				end
				if num == 0 then
					continue
				end

				local button = self.factionButtonsPanel:Add("ixMenuSelectionButton")
				button:SetBackgroundColor(v.color or color_white)
				button:SetText(L(v.name):utf8upper())
				button:SizeToContents()
				button:SetButtonList(self.factionButtons)
				button.faction = v.index
				button.OnSelected = function(panel)
					--self:PopulateSegments()

					self.classModel:SetModel("models/error.mdl")

					local faction = ix.faction.indices[panel.faction]
					--local models = faction:GetModels(LocalPlayer())

					self.payload:Set("faction", panel.faction)
					--self.payload:Set("model", math.random(1, #models))

					self:populateClassButtons()

					local num_of_classes = 0
					for _, v in SortedPairs(ix.class.list) do
						if v.faction == panel.faction && ix.class.HasClassWhitelist(v.index) then
							num_of_classes = num_of_classes + 1
						end
					end

					if num_of_classes == 1 then
						local class = ix.class.list[self.classButtons[1].class]
						local models = class:GetModels(LocalPlayer())
	
						self.stats = {
							health = class.health,
							physical_damage_taken = class.physical_damage_taken,
							bullet_damage_taken = class.bullet_damage_taken,
							mental_strength = class.mental_strength,
							hunger = class.hunger,
							thirst = class.thirst,
							speed = class.speed,
							jump_power = class.jump_power,
							max_stamina = class.max_stamina,
						}
	
						self.payload:Set("class", self.classButtons[1].class)
						self.payload:Set("model", math.random(1, #models))
					end
				end

				if ((lastSelected and lastSelected == v.index) or (!lastSelected and v.isDefault)) then
					button:SetSelected(true)
					lastSelected = v.index
				end
			end
		end

		self:populateClassButtons()
	end

	-- remove panels created for character vars
	for i = 1, #self.repopulatePanels do
		self.repopulatePanels[i]:Remove()
	end

	self.repopulatePanels = {}

	-- payload is empty because we attempted to send it - for whatever reason we're back here again so we need to repopulate
	if (!self.payload.faction) then
		for _, v in pairs(self.factionButtons) do
			if (v:GetSelected()) then
				v:SetSelected(true)
				break
			end
		end
	end

	self.factionButtonsPanel:SizeToContents()
	self.classButtonsPanel:SizeToContents()

	local zPos = 1

	-- set up character vars
	for k, v in SortedPairsByMemberValue(ix.char.vars, "index") do
		if (!v.bNoDisplay and k != "__SortedIndex") then
			local container = self:GetContainerPanel(v.category or "description")

			if (v.ShouldDisplay and v:ShouldDisplay(container, self.payload) == false) then
				continue
			end

			local panel

			-- if the var has a custom way of displaying, we'll use that instead
			if (v.OnDisplay) then
				panel = v:OnDisplay(container, self.payload)
				
			elseif (isstring(v.default)) then
				panel = container:Add("ixTextEntry")
				panel:Dock(TOP)
				panel:SetFont("ixMenuButtonHugeFont")
				panel:SetUpdateOnType(true)
				panel.OnValueChange = function(this, text)
					self.payload:Set(k, text)
				end

				if v.setDefault then
					panel:SetText(v.default)
					self.payload:Set(k, v.default)
				end

			elseif (isnumber(v.default)) then
				panel = container:Add("ixTextEntry")
				panel:SetHeight(64)
				panel:Dock(TOP)

				slider = panel:Add("DNumSlider")
				slider:Dock(FILL)
				slider:SetText("")
				slider:SetMin(v.min or 0)
				slider:SetMax(v.max or 100)
				slider:SetDecimals(v.decimals or 0)
				slider:SetValue(v.default)
				slider.OnValueChanged = function(this, value)
					if v.OnValueChanged then
						v:OnValueChanged(value, self.payload)
					end

					self.payload:Set(k, value)
				end

				if v.setDefault then
					panel:SetText(v.default)
					self.payload:Set(k, v.default)
				end
			end

			if (IsValid(panel)) then
				if v.hint then
					panel:SetTooltip(L(v.hint))

					local hint = panel:Add("DLabel")
					hint:SetFont("ixMenuButtonLabelFont")
					hint:SetText(L(v.hint))
					hint:SizeToContents()
					hint:DockMargin(0, 2, 0, 0)
					hint:Dock(RIGHT)
				end

				-- add label for entry
				local label = container:Add("DLabel")
				label:SetFont("ixMenuButtonLabelFont")
				label:SetText(L(k):utf8upper())
				label:SizeToContents()
				label:DockMargin(0, 16, 0, 2)
				label:Dock(TOP)

				-- we need to set the docking order so the label is above the panel
				label:SetZPos(zPos - 1)
				panel:SetZPos(zPos)

				self:AttachCleanup(label)
				self:AttachCleanup(panel)

				if (v.OnPostSetup) then
					v:OnPostSetup(panel, self.payload)
				end

				zPos = zPos + 2
			end
		end
	end

	if (!self.bInitialPopulate) then
		self:PopulateSegments()
	end

	self.bInitialPopulate = true
end

function PANEL:VerifyProgression(name)
	for k, v in SortedPairsByMemberValue(ix.char.vars, "index") do
		if (name ~= nil and (v.category or "description") != name) then
			continue
		end

		local value = self.payload[k]

		if (!v.bNoDisplay or v.OnValidate) then
			if (v.OnValidate) then
				local result = {v:OnValidate(value, self.payload, LocalPlayer())}

				if (result[1] == false) then
					self:GetParent():ShowNotice(3, L(unpack(result, 2)))
					return false
				end
			end

			self.payload[k] = value
		end
	end

	return true
end

function PANEL:Paint(width, height)
	derma.SkinFunc("PaintCharacterCreateBackground", self, width, height)
	BaseClass.Paint(self, width, height)
end

vgui.Register("ixCharMenuNew", PANEL, "ixCharMenuPanel")
