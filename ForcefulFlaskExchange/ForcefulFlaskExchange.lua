--[[
Работает через макрос /run TradeForcefulFlask() или кнопку "FR Flask" внутри фрема обмена.

По команде /run TradeForcefulFlask():
Открывает обмен по таргету
Разъединяет стак
Перекладывает в окно обмена 1ед. настоя
Предлагает обмен

Присутствует проверка на выданные фласки. Игрок повторно не сможет получить фласку в течение 50 минут.

]]

if FFE_Conf == nil then FFE_Conf = {} end

local TalentQuery = LibStub:GetLibrary("LibTalentQuery-1.0");
local talentLib = LibStub:GetLibrary("LibGroupTalents-1.0");
local DataForcefulFlaskBag = {};

local ForcefulFlaskTable = {
	["melee"] = 270002,
	["caster"] = 270001,
	["healer"] = 270001,
	["tank"] = 270002,
	["resist"] = 270000,
	["resilence"] = 270005,
};

function PartyOrRaid(name) if --[[UnitInParty(name) == 1 or]] UnitInRaid(name) == 1 then return true end end

function ForcefulFlaskCheck(RecipientName, Role)
	if  FFE_Conf[RecipientName] == nil or (FFE_Conf[RecipientName] ~= nil and FFE_Conf[RecipientName] <= time()) then
		print("|c0040FF40Выдача фласки разрешена.", RecipientName, Role);
		return true
	elseif FFE_Conf[RecipientName] ~= nil and FFE_Conf[RecipientName] >= time() then
		print(RecipientName.." |c00FF4040Уже получал фласку, следующую можно будет получить через: "..math.floor((FFE_Conf[RecipientName] - time()) / 60) .." минут(ы)");
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

function ForcefulFlaskBagData(idFlask)
	SearchForcefulFlasks();
	for k, v in pairs(DataForcefulFlaskBag[idFlask]) do
		if v.count == 1 then
			return v.bag, v.slot, v.count
		end
	end
	for k, v in pairs(DataForcefulFlaskBag[idFlask]) do
		if v.count > 1 then
			local bag, slot = EmptySlotEx()
			
			SplitContainerItem(v.bag, v.slot, 1);
			PickupContainerItem(bag, slot);
			
			return bag, slot, 1
		end
	end
end

function SearchForcefulFlasks()
	DataForcefulFlaskBag = {}; 
	DataForcefulFlaskBag[270001] = {}; 
	DataForcefulFlaskBag[270002] = {}; 
	DataForcefulFlaskBag[270005] = {}; 
	DataForcefulFlaskBag[270000] = {}; 
	
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = GetContainerItemID(bag, slot);
			local _, count = GetContainerItemInfo(bag, slot);
			
			if id == 270001 or id == 270002 or id == 270000 or id == 270005 then
				DataForcefulFlaskBag[id][bag..slot] = {
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

function TradeForcefulFlask()

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
			
			local ForcefulFlaskID = ForcefulFlaskTable[Role];
			local bag, slot = ForcefulFlaskBagData(ForcefulFlaskID);
			
			if ForcefulFlaskCheck(RecipientName, Role) and bag then
				PickupContainerItem(bag, slot);
				ClickTradeButton(1);
			end
			
		elseif numItems == 1 then
			AcceptTrade();
		end
	
	else
		local name = UnitName("target");
		
		if UnitInRaid(name) or UnitInParty(name) then
		
			BuffForcefulFlaskCheck(name);
			
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
			
			local ForcefulFlaskID = ForcefulFlaskTable[Role];
			local bag, slot = ForcefulFlaskBagData(ForcefulFlaskID);
			InitiateTrade("target");
		end
	end
end

function TradeResistFlask()

	if (TradeFrame) and TradeFrame:IsShown() == 1 then
		local RecipientName = TradeFrameRecipientNameText:GetText();
		local ItemTrade, _, numItems = GetTradePlayerItemInfo(1);
			
		if (UnitInRaid(RecipientName) or UnitInParty(RecipientName)) and ItemTrade == nil then
				
			local ForcefulFlaskID = ForcefulFlaskTable["resist"];
			local bag, slot = ForcefulFlaskBagData(ForcefulFlaskID);
			
			if ForcefulFlaskCheck(RecipientName, "resist") and bag then
				PickupContainerItem(bag, slot);
				ClickTradeButton(1);
			end
			
		elseif numItems == 1 then
			AcceptTrade();
		end
	
	else
		local name = UnitName("target");
		
		if UnitInRaid(name) or UnitInParty(name) then
		
			BuffForcefulFlaskCheck(name);
			
			local ForcefulFlaskID = ForcefulFlaskTable["resist"];
			local bag, slot = ForcefulFlaskBagData(ForcefulFlaskID);
			InitiateTrade("target");
		end
	end
end

function TradeResilenceFlask()

	if (TradeFrame) and TradeFrame:IsShown() == 1 then
		local RecipientName = TradeFrameRecipientNameText:GetText();
		local ItemTrade, _, numItems = GetTradePlayerItemInfo(1);
			
		if (UnitInRaid(RecipientName) or UnitInParty(RecipientName)) and ItemTrade == nil then
				
			local ForcefulFlaskID = ForcefulFlaskTable["resilence"];
			local bag, slot = ForcefulFlaskBagData(ForcefulFlaskID);
			
			if ForcefulFlaskCheck(RecipientName, "resilence") and bag then
				PickupContainerItem(bag, slot);
				ClickTradeButton(1);
			end
			
		elseif numItems == 1 then
			AcceptTrade();
		end
	
	else
		local name = UnitName("target");
		
		if UnitInRaid(name) or UnitInParty(name) then
		
			BuffForcefulFlaskCheck(name);
			
			local ForcefulFlaskID = ForcefulFlaskTable["resilence"];
			local bag, slot = ForcefulFlaskBagData(ForcefulFlaskID);
			InitiateTrade("target");
		end
	end
end

function TradeAcceptForcefulFlask(self, event, arg1, arg2)
	if arg1 == 1 and arg2 == 1 then
		local NameTrade, texture, numItems = GetTradePlayerItemInfo(1);
		local RecipientName = TradeFrameRecipientNameText:GetText();
		
		if NameTrade ~= nil and string.match(NameTrade, "FR_Flask") and numItems == 1 then
		
			FFE_Conf[RecipientName] = time() + 3000,
			
			print("|c0040FF40Обмен флаской состоялся");
		end
	
	end
end

function TradeHelp()
	print("|c0040FF40 Основные команды ForcefulFlaskExchange");
	print("|c0040FF40 1) /run TradeForcefulFlask() - обмен апнутых фласок на АП/СПД");
	print("|c0040FF40 2) /run TradeResilenceFlask() - обмен апнутых фласок на РЕС");
	print("|c0040FF40 3) /run TradeResistFlask() - обмен апнутых фласок на СОПРОТИВЛЕНИЕ");
	print("|c0040FF40 -----------------------");
	print("|c0040FF40 Основные команды FreeAction");
	print("|c0040FF40 1) /run TradeFreeAction() - обмен на х ЗСД");
	print("|c0040FF40 2) /run ChangeFreeActionCount(x) - изменение количества выдаваемого ЗСД на х");
	print("|c0040FF40 -----------------------");
	print("|c0040FF40 Основные команды FlaskExchange");
	print("|c0040FF40 1) /run TradeFlask() - обмен обычных фласок на АП/СПД");
	print("|c0040FF40 -----------------------");
	print("|c0040FF40 /click TradeFrameTradeButton - команда для подтверждения трейда");
end

CreateFrame("Frame", "ForcefulFlaskTradeFrame")
ForcefulFlaskTradeFrame:SetScript("OnEvent", TradeAcceptForcefulFlask)
ForcefulFlaskTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")

local TradeForcefulFlaskButton = CreateFrame("Button", nil, TradeFrame, "UIPanelButtonTemplate")
TradeForcefulFlaskButton:SetPoint("BOTTOMLEFT", 100, 34)
TradeForcefulFlaskButton:SetSize(77, 22)
TradeForcefulFlaskButton:SetText("FR_Flask")
TradeForcefulFlaskButton:SetScript("OnClick", function(self, arg1)
    TradeForcefulFlask()
end)
local TradeResistFlaskButton = CreateFrame("Button", nil, TradeFrame, "UIPanelButtonTemplate")
TradeResistFlaskButton:SetPoint("BOTTOMLEFT", 50, 34)
TradeResistFlaskButton:SetSize(50, 22)
TradeResistFlaskButton:SetText("Resist")
TradeResistFlaskButton:SetScript("OnClick", function(self, arg1)
    TradeResistFlask()
end)
local TradeResilenceFlaskButton = CreateFrame("Button", nil, TradeFrame, "UIPanelButtonTemplate")
TradeResilenceFlaskButton:SetPoint("BOTTOMLEFT", 10, 34)
TradeResilenceFlaskButton:SetSize(40, 22)
TradeResilenceFlaskButton:SetText("Res")
TradeResilenceFlaskButton:SetScript("OnClick", function(self, arg1)
    TradeResilenceFlask()
end)
--
local BuffFlask = {
	[270008] = "tank",
	[270008] = "melee",
	[270007] = "caster",
	[270007] = "healer",
	[270006] = "resist",
	[270011] = "resilence",
};

function BuffForcefulFlaskCheck(name)
	for i = 1, 40 do 
		local _, _, _, _, _, _, endTime, _, _, _, spellID = UnitBuff(name, i);
		if spellID ~= nil and BuffFlask[spellID] then
			local remaining = endTime-GetTime();
			print("Есть баф фласки", math.ceil(remaining/60).." минут(ы)")
		end
	end
end

