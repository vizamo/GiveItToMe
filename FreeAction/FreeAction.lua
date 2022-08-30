--[[
Работает через макрос /run TradeFreeAction() или кнопку "ЗСД" внутри фрема обмена.

По команде /run TradeFreeAction():
Открывает обмен по таргету
Разъединяет стак
Перекладывает в окно обмена FreeActionCountSet() ед. зелья
Предлагает обмен

Для изменения количества выдаваемого зсд, измение значение в команде /run ChangeFreeActionCount(x)
]]

if FA_Conf == nil then FA_Conf = {} end

local TalentQuery = LibStub:GetLibrary("LibTalentQuery-1.0");
local talentLib = LibStub:GetLibrary("LibGroupTalents-1.0");
local DataFreeActionBag = {};

local FreeActionTable = {
	["melee"] = 5634,
	["caster"] = 5634,
	["healer"] = 5634,
	["tank"] = 5634,
};

function PartyOrRaid(name) if --[[UnitInParty(name) == 1 or]] UnitInRaid(name) == 1 then return true end end

function FreeActionCountSet()
	FACH = FA_Conf["FreeActionCountChanged"];
	if  FA_Conf["FreeActionCountChanged"] == nil then
		return 3
	elseif FA_Conf["FreeActionCountChanged"] ~= nil then
		return FACH;
	end
end

function ChangeFreeActionCount(facount)
	FA_Conf["FreeActionCountChanged"] = facount;
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

function FreeActionBagData(idFreeAction)
	SearchFreeActions();
	for k, v in pairs(DataFreeActionBag[idFreeAction]) do
		if v.count == FreeActionCountSet() then
			return v.bag, v.slot, v.count
		end
	end
	for k, v in pairs(DataFreeActionBag[idFreeAction]) do
		if v.count > FreeActionCountSet() then
			local bag, slot = EmptySlotEx()
			
			SplitContainerItem(v.bag, v.slot, FreeActionCountSet());
			PickupContainerItem(bag, slot);
			
			return bag, slot, 1
		end
	end
end

function SearchFreeActions()
	DataFreeActionBag = {}; 
	DataFreeActionBag[5634] = {}; 

	
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local id = GetContainerItemID(bag, slot);
			local _, count = GetContainerItemInfo(bag, slot);
			
			if id == 5634 then
				DataFreeActionBag[id][bag..slot] = {
					["bag"] = bag,
					["slot"] = slot,
					["count"] = count,
				}
			end
		end
	end
end

function TradeFreeAction()

	if (TradeFrame) and TradeFrame:IsShown() == 1 then
		local RecipientName = TradeFrameRecipientNameText:GetText();
		local ItemTrade, _, numItems = GetTradePlayerItemInfo(2);
			
		if (UnitInRaid(RecipientName) or UnitInParty(RecipientName)) and ItemTrade == nil then
		
			local FreeActionID = 5634;
			
			local bag, slot = FreeActionBagData(FreeActionID);
			
			if bag then
				PickupContainerItem(bag, slot);
				ClickTradeButton(2);
			end
			
		elseif numItems == FreeActionCountSet() then
			AcceptTrade();
		end
	
	else
		local name = UnitName("target");
		
		if UnitInRaid(name) or UnitInParty(name) then
			
			
			local FreeActionID = 5634;
			local bag, slot = FreeActionBagData(FreeActionID);
			InitiateTrade("target");
		end
	end
end

function TradeAcceptFreeAction(self, event, arg1, arg2)
	if arg1 == 1 and arg2 == 1 then
		local NameTrade, texture, numItems = GetTradePlayerItemInfo(1);
		local RecipientName = TradeFrameRecipientNameText:GetText();
		
		if NameTrade ~= nil and string.match(NameTrade, "ЗСД") and numItems == FreeActionCountSet() then
		
			print("|c0040FF40Обмен ЗСД состоялся");
		end
	
	end
end
CreateFrame("Frame", "FreeActionTradeFrame")
FreeActionTradeFrame:SetScript("OnEvent", TradeAcceptFreeAction)
FreeActionTradeFrame:RegisterEvent("TRADE_ACCEPT_UPDATE")

local TradeFreeActionButton = CreateFrame("Button", nil, TradeFrame, "UIPanelButtonTemplate")
TradeFreeActionButton:SetPoint("BOTTOMLEFT", 20, 56)
TradeFreeActionButton:SetSize(77, 22)
TradeFreeActionButton:SetText("ЗСД")
TradeFreeActionButton:SetScript("OnClick", function(self, arg1)
    TradeFreeAction()
end)
--


