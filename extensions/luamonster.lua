module("extensions.luamonster", package.seeall)  
extension = sgs.Package("monster")            

bianshi = sgs.General(extension, "bianshi", "wei") 

jiahuo = sgs.CreateViewAsSkill{ 
	name = "jiahuo",
	n = 1,
	view_filter = function(self, selected, to_select)
		return to_select:isBlack() -- == sgs.Card_Club and not to_select:isEquipped()
	end,
	
	view_as = function(self, cards)
		if #cards == 1 then
			local card = cards[1]
			local new_card =sgs.Sanguosha:cloneCard("collateral", card:getSuit(), card:getNumber())
			new_card:addSubcard(card:getId())
			new_card:setSkillName(self:objectName())
			return new_card
		end
	end
}

dianmu=sgs.CreateTriggerSkill{
	name="dianmu",
	events=sgs.Predamage,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage=data:toDamage()
	
		damage.nature = sgs.DamageStruct_Thunder
--		damage.chain = true
		data:setValue(damage)
		return false
	end,
}

yaohou=sgs.CreateTriggerSkill{
	name="yaohou",
	events=sgs.Damage,
--	frequency=sgs.Skill_Compulsory,
	can_trigger = function()
		return true
	end,
	on_trigger=function(self,event,player,data)
		local room = player:getRoom()
		local damage=data:toDamage()
		local bianshi = room:findPlayerBySkillName(self:objectName())
	
		if damage.from:isLord() and damage.from:getGeneral():isMale() then
			if (room:askForSkillInvoke(bianshi,self:objectName()) and not damage.to:isNude() ) then 
				local card_id = room:askForCardChosen(bianshi, damage.to, "he", "yaohou")
				if(room:getCardPlace(card_id) == sgs.Player_Hand) then
					room:moveCardTo(sgs.Sanguosha:getCard(card_id), bianshi, sgs.Player_Hand, false)
				else
					room:obtainCard(bianshi, card_id)
				end
			room:playSkillEffect("yaohou")
			else
				bianshi:drawCards(1)
			end
		end
--		damage.chain = true
--		data:setValue(damage)
		return false
	end,
}


sgs.LoadTranslationTable{
	["jiahuo"] = "嫁祸",
	[":jiahuo"] = "出牌阶段，你可以将任意一张♣或♠牌当【借刀杀人】使用，每回合限一次。",
	["dianmu"] = "电母",
	[":dianmu"] = "锁定技，你造成的所有伤害均视为雷电伤害。",
	["yaohou"] = "妖后",
	[":yaohou"] = "皇后技，若主公为男性角色，主公对任意一名角色造成一次伤害，你可以选择执行下列两项中的一项;1.你立即从该角色出获得一张牌；2.立即摸一张牌。",
}


bianshi:addSkill(jiahuo)
bianshi:addSkill(dianmu)
bianshi:addSkill(yaohou)
