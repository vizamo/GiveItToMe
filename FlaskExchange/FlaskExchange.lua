--[[
Работает через макрос /run TradeFlask() или кнопку "Настой" внутри фрема обмена.

По команде /run TradeFlask():
Открывает обмен по таргету
Разъединяет стак
Перекладывает в окно обмена 1ед. настоя
Предлагает обмен

Присутствует проверка на выданные фласки. Игрок повторно не сможет получить фласку в течение 50 минут.

]]

if FE_Conf == nil then FE_Conf = {} end

local TalentQuery = LibStub:GetLibrary("LibTalentQuery-1.0");
local talentLib = LibStub:GetLibrary("LibGroupTalents-1.0");
local DataFlaskBag = {};

local FlaskTable = {
	["melee"] = 46377,
	["caster"] = 46376,
	["healer"] = 46376,
	["tank"] = 46377,
};

function PartyOrRaid(name) if --[[UnitInParty(name) == 1 or]] UnitInRaid(name) == 1 then return true end end

function FlaskCheck(RecipientName, Role)
	if  FE_Conf[RecipientName] == nil or (FE_Conf[RecipientName] ~= nil and FE_Conf[RecipientName] <= time()) then
		print("|c0040FF40Выдача фласки разрешена.", RecipientName, Role);
		return true
	elseif FE_Conf[RecipientName] ~= nil and FE_Conf[RecipientName] >= time() then
		print(RecipientName.." |c00FF4040Уже получал фласку, следующую можно будет получить через: "..math.floor((FE_Conf[RecipientName] - time()) / 60) .." минут(ы)");
		return false;
	end
end

function EmptySlotEx()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = GetContainerItemID(bag, slot);
			if id == nil then 
				return bag, slot;
			end	
		end
	end
end

function FlaskBagData(idFlask)
	SearchFlasks();
	for k, v in pairs(DataFlaskBag[idFlask]) do
		if v.count == 1 then
			return v.bag, v.slot, v.count
		end
	end
	for k, v in pairs(DataFlaskBag[idFlask]) do
		if v.count > 1 then
			local bag, slot = EmptySlotEx()
			
			SplitContainerItem(v.bag, v.slot, 1);
			PickupContainerItem(bag, slot);
			
			return bag, slot, 1
		end
	end
end

function SearchFlasks()
	DataFlaskBag = {}; 
	DataFlaskBag[46377] = {}; 
	DataFlaskBag[46376] = {}; 
	DataFlaskBag[46379] = {};
	
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = GetContainerItemID(bag, slot);
			local _, count = GetContainerItemInfo(bag, slot);
			
			if id == 46377 or id == 46376 or id == 46379 then
				DataFlaskBag[id][bag..slot] = {
					["bag"] = bag,
					["slot"] = slot,
					["count"] = count,
				}
			end
		end
	end
end

function GetMana(RecipientName)
	local ManaMax = UnitManaMax(RecipientName); --Returns count of mana
	
	if ManaMax > 11000 then
		return "caster"
	else
		return "melee"
	end
end

function TradeFlask()

	if (TradeFrame) and TradeFrame:IsShown() == 1 then
		local RecipientName = TradeFrameRecipientNameText:GetText();
		local ItemTrade, _, numItems = GetTradePlayerItemInfo(1);
			
		if (UnitInRaid(RecipientName) or UnitInParty(RecipientName)) and ItemTrade == nil then
				
			local Class = UnitClass(RecipientName);
			local ClassesArray = {
							["Рыцарь смерти"] = "melee",
							["Охотник"] = "melee",
							["Охотница"] = "melee",
							["Воин"] = "melee",
							["Друид"] = "caster",
							["Шаман"] = "caster",
							["Шаманка"] = "caster",
							["Паладин"] = GetMana(RecipientName),
							["Чернокнижник"] = "caster",
							["Чернокнижница"] = "caster",
							["Жрец"] = "caster",
							["Жрица"] = "caster",
							["Маг"] = "caster",
							["Разбойник"] = "melee",
							["Разбойница"] = "melee"
			};


			local Role = ClassesArray[Class];
			
			local FlaskID = FlaskTable[Role];
			local bag, slot = FlaskBagData(FlaskID);
			
			if FlaskCheck(RecipientName, Role) and bag then
				PickupContainerItem(bag, slot);
				ClickTradeButton(1);
			end
			
		elseif numItems == 1 then
			AcceptTrade();
		end
	
	else
		local name = UnitName("target");
		
		if UnitInRaid(name) or UnitInParty(name) then
		
			BuffFlaskCheck(name);
			
			local Class = UnitClass(name);
			local ClassesArray = {
							["Рыцарь смерти"] = "melee",
							["Охотник"] = "melee",
							["Охотница"] = "melee",
							["Воин"] = "melee",
							["Друид"] = "caster",
							["Шаман"] = "caster",
							["Шаманка"] = "caster",
							["Паладин"] = GetMana(name),
							["Чернокнижник"] = "caster",
							["Чернокнижница"] = "caster",
							["Жрец"] = "caster",
							["Жрица"] = "caster",
							["Маг"] = "caster",
							["Разбойник"] = "melee",
							["Разбойница"] = "melee"
			};


			local Role = ClassesArray[Class];
			
			local FlaskID = FlaskTable[Role];
			local bag, slot = FlaskBagData(FlaskID);
			InitiateTrade("target");
		end
	end
end

function TradeAcceptFlask(self, event, arg1, arg2)
	if arg1 == 1 and arg2 == 1 then
		local NameTrade, texture, numItems = GetTradePlayerItemInfo(1);
		local RecipientName = TradeFrameRecipientNameText:GetText();
		
		if NameTrade ~= nil and string.match(NameTrade, "Настой") and numItems == 1 then
		
			FE_Conf[RecipientName] = time() + 3000,
			
			print("|c0040FF40Обмен флаской состоялся");
		end
	
	end
end
CreateFrame("Frame", "FlaskTradeFrame")
FlaskTradeFrame:SetScript("OnEvent", TradeAcceptFlask)
FlaskTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")

local TradeFlaskButton = CreateFrame("Button", nil, TradeFrame, "UIPanelButtonTemplate")
TradeFlaskButton:SetPoint("BOTTOMLEFT", 100, 56)
TradeFlaskButton:SetSize(77, 22)
TradeFlaskButton:SetText("Настой")
TradeFlaskButton:SetScript("OnClick", function(self, arg1)
    TradeFlask()
end)
--
local BuffFlask = {
	[53758] = "tank",
	[53760] = "melee",
	[53755] = "caster",
};

function BuffFlaskCheck(name)
	for i = 1, 40 do 
		local _, _, _, _, _, _, endTime, _, _, _, spellID = UnitBuff(name, i);
		if spellID ~= nil and BuffFlask[spellID] then
			local remaining = endTime-GetTime();
			print("Есть баф фласки", math.ceil(remaining/60).." минут(ы)")
		end
	end
end

