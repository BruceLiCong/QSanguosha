module("extensions.luamonster", package.seeall)  
extension = sgs.Package("monster")            

bianshi = sgs.General(extension, "bianshi", "wei", "3", false)
yaozhangjiao = sgs.General(extension, "yaozhangjiao", "qun", "3")
yaoxiaoqiao = sgs.General(extension, "yaoxiaoqiao", "wu", "3", false)    

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
			sgs.Self:setFlags("jhused")
			return new_card
		end
	end,
	enabled_at_play=function()
		 if  sgs.Self:getPhase()==sgs.Player_Finish then sgs.Self:getRoom():setPlayerFlag(sgs.Self,"-jhused") end 
		 return not sgs.Self:hasFlag("jhused")        --出牌时可以使用
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
	end,
}

taiping=sgs.CreateViewAsSkill{
name="taiping",
n=2, --需要两张牌
suit,
tp_card,
view_filter=function(self, selected, to_select)
        if #selected ==0 then return not to_select:isEquipped() end --非装备
        if #selected == 1 then --限制两张颜色一样
                        suit = selected[1]:getSuit()
                        return (not to_select:isEquipped()) and to_select:getSuit() == suit
        else return false
        end        
end,
view_as=function(self, cards)
        if #cards==0 then return nil end        
        if #cards==2 then    --若选择好了2张   
			if suit == sgs.Card_Spade then
                tp_card = sgs.Sanguosha:cloneCard("savage_assault",sgs.Card_Spade, 0)      --克隆一张无颜色无点数的万箭齐发 
			elseif suit == sgs.Card_Heart then	
				tp_card = sgs.Sanguosha:cloneCard("archery_attack",sgs.Card_Heart, 0)
			elseif suit == sgs.Card_Club then	
				tp_card = sgs.Sanguosha:cloneCard("amazing_grace",sgs.Card_Club, 0)	
			elseif suit == sgs.Card_Diamond then	
				tp_card = sgs.Sanguosha:cloneCard("god_salvation",sgs.Card_Diamond, 0)	
			end				
			tp_card:addSubcard(cards[1])    --两张牌成为子卡    
			tp_card:addSubcard(cards[2])
			tp_card:setSkillName(self:objectName())
			sgs.Self:setFlags("tpused")
			return tp_card end  --返回这个万箭齐发       
end,
enabled_at_play=function()
	 if  sgs.Self:getPhase()==sgs.Player_Finish then sgs.Self:getRoom():setPlayerFlag(sgs.Self,"-tpused") end 
	 return not sgs.Self:hasFlag("tpused")        --出牌时可以使用
end,
enabled_at_response=function(self,pattern)        
        return false  --不响应打出
end
}

jiazi=sgs.CreateTriggerSkill{
	name="jiazi",
	events=sgs.PhaseChange,
	frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		if player:getPhase()==sgs.Player_Finish then
			local room = player:getRoom()
			if room:askForSkillInvoke(player,"jiazi") then
				if player:getHandcardNum() < player:getHp() then
            		player:drawCards(player:getHp() - player:getHandcardNum())
                	room:playSkillEffect("jiazi");
				end
			end
			return false
		end
	end,
}

tuzhong=sgs.CreateTriggerSkill{
	name="tuzhong",
	events=sgs.PhaseChange,
	frequency=sgs.Skill_NotFrequent,
	on_trigger=function(self,event,player,data)
		if player:getPhase()==sgs.Player_Draw then
			local room = player:getRoom()
			local list=sgs.SPlayerList() 
			for _,p in sgs.qlist(room:getOtherPlayers(player)) do
				if(p:isWounded()) then --若在其攻击范围
					list:append(p) --加入列表
				end
			end		
			if (not list:isEmpty()) and room:askForSkillInvoke(player,"tuzhong") then
				local target = room:askForPlayerChosen(player, list, "tuzhong")
            	local recov = sgs.RecoverStruct()
				recov.recover = 1
--				recov.card = self
				recov.who = target		
				room:recover(target, recov)
		       	room:playSkillEffect("tuzhong");
				return true
			end
			return false
		end
	end,
}

tongque=sgs.CreateTriggerSkill{
	name="tongque",
	events=sgs.CardEffected,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local card=data:toCardEffect().card--记录使用的卡
		if not (card:inherits("Analeptic") or card:inherits("IronChain")) then return false end--卡片种类不符则不发动
		SkillLog(player,self:objectName(),0,0)
		SkillLog(player,self:objectName(),1,0)
		return true--卡片无效
	end
}

sgs.LoadTranslationTable{
	["jiahuo"] = "嫁祸",
	[":jiahuo"] = "出牌阶段，你可以将任意一张♣或♠牌当【借刀杀人】使用，每回合限一次。",
	["dianmu"] = "电母",
	[":dianmu"] = "锁定技，你造成的所有伤害均视为雷电伤害。",
	["yaohou"] = "妖后",
	[":yaohou"] = "皇后技，若主公为男性角色，主公对任意一名角色造成一次伤害，你可以选择执行下列两项中的一项;1.你立即从该角色出获得一张牌；2.立即摸一张牌。",
	["taiping"] = "太平",
	[":taiping"] = "出牌阶段，你可以将任意两张♠手牌当【南蛮入侵】使用，用人一两张♥手牌当【万箭齐发】使用，任意两张♣手牌当【五谷丰登】使用，任意两张♦手牌当【桃园结义】使用。每回合限一次。",
	["jiazi"] = "甲子",
	[":jiazi"] = "回合结束，根据当前体力值补满手牌。",
	["tuzhong"] = "徒眾",
	[":tuzhong"] = "主公技，主动放弃摸牌阶段，令除你以外的任意一名角色恢复一点体力。",
	["quwu"] = "曲误",
	[":quwu"] = "出牌阶段，指定攻击范围内任意一名角色，下一个摸牌阶段少摸一张牌，而你在他的摸牌阶段摸一张牌，每回合限一次。",
	["tongque"] = "铜雀",
	[":tongque"] = "不受【酒】和【铁索连环】的影响。",
	["zhongshang"] = "冢殇",
	[":zhongshang"] = "每死亡一名角色，手牌上限+1。",
	
}


bianshi:addSkill(jiahuo)
bianshi:addSkill(dianmu)
bianshi:addSkill(yaohou)

yaozhangjiao:addSkill(taiping)
yaozhangjiao:addSkill(jiazi)
yaozhangjiao:addSkill(tuzhong)

yaoxiaoqiao:addSkill(tongque)