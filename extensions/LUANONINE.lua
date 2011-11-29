module("extensions.LUANONINE", package.seeall)
extension = sgs.Package("LUANONINE")

xiahouzt = sgs.General(extension, "xiahouzt", "wei",4)
function used(player,cdname)
	return not  player:hasUsed(cdname)
end

ganglieEX=sgs.CreateTriggerSkill{
name="ganglieEX",
frequency=sgs.Skill_Compulsory,
events={sgs.HpRecover,sgs.Damaged},
on_trigger=function(self,event,player,data)
		local room = player:getRoom()
	if event==sgs.Damaged then	
		local damage = data:toDamage()	--获取伤害结构体
        local from = damage.from --伤害来源
		if from:objectName() ~= player:objectName() then --恩怨部分
			room:playSkillEffect("enyuan", math.random(3,4)) --音效随机	
			local card = room:askForCard(from,".enyuan", "@enyuan") --恩怨要求展示并给你一张红桃牌
			if card~=nil then --若选择了红桃牌
				 room:showCard(from,card:getEffectiveId()) --展示
				 player:obtainCard(card) --绑定给技能拥有者
			else --若没给红桃牌
				room:loseHp(from,1) --伤害来源流失体力
			end	
		end			
        if  not (from~=nil and from:isAlive() and room:askForSkillInvoke(player,self:objectName())==true) --刚烈部分
           then return end
           room:playSkillEffect("ganglie")		
           local judge=sgs.JudgeStruct() --判定结构
           judge.pattern=sgs.QRegExp("(.*):(heart):(.*)")
           judge.good=false
           judge.reason="ganglieex"
           judge.who=player
           room:judge(judge)
        if judge:isGood() then				
            if not(room:askForDiscard(from,self:objectName(),2,true,false)) then --若没有弃牌 （此弃牌可取消，不包括装备）
					local damagetmp=sgs.DamageStruct() --伤害结构
					damagetmp.damage=1
					damagetmp.from=player
					damagetmp.to=from
					damagetmp.nature=sgs.DamageStruct_Normal --无属性
					damagetmp.chain=false --不连环					
					room:damage(damagetmp)	
			end					
		 end
	elseif event==sgs.HpRecover then --其他角色每令你回复1点体力，该角色摸一张牌
		 local rec = data:toRecover()		--获取回复结构体 
		 rec.who:drawCards(rec.recover)  --摸回复点数的牌
		 local log=sgs.LogMessage() --以下为恩怨体力回复时的LOGTYPE
		 log.from =player
		 log.type ="#EnyuanRecover"
		 log.to:append(rec.who)		
		 log.arg =tonumber(rec.recover) 		 
		 room:sendLog(log)		 
		 room:playSkillEffect("enyuan", math.random(1,2)) --音效随机		
	end
end
}

xuanjiEXcard=sgs.CreateSkillCard{  --炫惑卡片
name="xuanjiEXcard",
once=true,
will_throw=false,
on_effect=function(self,effect)	
	effect.to:obtainCard(self) --给牌
	local room=effect.from:getRoom() 	
 	local card_id = room:askForCardChosen(effect.from, effect.to, "he", "xuanhuo") --选牌
    local card = sgs.Sanguosha:getCard(card_id) 
	room:playSkillEffect("xuanhuo", math.random(1,2))
    local is_public = room:getCardPlace(card_id) ~= sgs.Player_Hand
    room:moveCardTo(card, effect.from, sgs.Player_Hand, not is_public) --先拿回手里
    local ts = room:getOtherPlayers(effect.to) --除了被炫角色的目标
    local t= room:askForPlayerChosen(effect.from, ts, "xuanhuo") --选一个
    if(t:objectName() ~= effect.from:objectName()) then  
        room:moveCardTo(card, t,  sgs.Player_Hand, false) --交出去
	end		
	room:setPlayerFlag(effect.from,"xjused")	 --使用过的标记
end		
}

xuanji=sgs.CreateViewAsSkill{ --眩惑视为技能
name="xuanji",
n=1,
view_filter=function(self, selected, to_select)
	return  to_select:isRed()  -- 改成 (not  to_select:isEquipped()) and  to_select:getSuit() == sgs.Card_Heart 则为红桃非装备区
end,
view_as=function(self, cards)
	if #cards==1 then 
	local acard=xuanjiEXcard:clone() 
	acard:addSubcard(cards[1])
    acard:setSkillName(self:objectName())     
	return acard
	end
end,
enabled_at_play=function() --没限制次数
    if  sgs.Self:getPhase()==sgs.Player_Finish then sgs.Self:getRoom():setPlayerFlag(sgs.Self,"-xjused") end --回合结束取消标记
	return not sgs.Self:hasFlag("xjused") 
end,
enabled_at_response=function(self,pattern) 
	return false 
end
}


fanjianEXcard=sgs.CreateSkillCard{  --反间卡片
name="fanjianEXcard",
once=true,
will_throw=false,
on_effect=function(self,effect)		   
	local room=effect.from:getRoom() 
 	room:playSkillEffect("fanjian", math.random(1,2))
	local card_id = effect.from:getRandomHandCardId()
    local card = sgs.Sanguosha:getCard(card_id)	
    local suit = room:askForSuit(effect.to)
	local emptycard=sgs.Sanguosha:cloneCard("slash",suit,0) 
    local log=sgs.LogMessage() 
    log.type = "#ChooseSuit"
    log.from = effect.to
    log.arg =emptycard:getSuitString()
	emptycard=nil
    room:sendLog(log)
    room:getThread():delay()
    effect.to:obtainCard(card)
    room:showCard(effect.to, card_id)
    if (card:getSuit() ~= suit) then
	local damagetmp=sgs.DamageStruct() --伤害结构
					damagetmp.damage=1
					damagetmp.from=effect.from
					damagetmp.to=effect.to
					damagetmp.nature=sgs.DamageStruct_Normal --无属性
					damagetmp.chain=false --不连环					
					room:damage(damagetmp)	       
    end
	 room:setPlayerFlag(effect.from,"fjused") --使用过的标记
end		
}

fanjianEX=sgs.CreateViewAsSkill{ --眩惑视为技能
name="fanjianEX",
n=0,
view_as=function(self, cards)
	if #cards==0 then 
	local acard=fanjianEXcard:clone() 	
    acard:setSkillName(self:objectName())     
	return acard
	end
end,
enabled_at_play=function() --没限制次数
	 if  sgs.Self:getPhase()==sgs.Player_Finish then sgs.Self:getRoom():setPlayerFlag(sgs.Self,"-fjused") end --回合结束取消标记
	return (not sgs.Self:isKongcheng() ) 
end,
enabled_at_response=function(self,pattern) 
	return false 
end
}


xiahouzt:addSkill(ganglieEX) 
xiahouzt:addSkill(xuanji) 
xiahouzt:addSkill(fanjianEX) 

sgs.LoadTranslationTable{
	["LUANONINE"] = "教程9",	
	["xiahouzt"] = "夏侯正太",
	["~xiahouzhengtai"] = "肛····都漏了",
	["ganglieEX"]="肛裂",
	[":ganglieEX"]="其他角色每令你回复1点体力，该角色摸一张牌；其他角色每对你造成一次伤害，须给你一张♥手牌，否则该角色失去1点体力,\
	然后你还可进行一次判定：若结果不为红桃，则目标来源必须进行二选一：弃两张手牌或受到你对其造成的1点伤害。",
	["xuanji"]="炫基",
	[":xuanji"]="出牌阶段,你可将一张红色牌交给一名其他角色,然后,你获得该角色的一张牌并立即交给除该角色外的其他角色。每回合限使用1次",
	["fanjianEX"]="反奸",
	["fanjianEX"]="反奸",
	[":fanjianEX"]="出牌阶段，你可以指定一名其他角色，该角色选择一种花色后获得你的一张手牌并展示之，若此牌与所选花色不同，则你对该角色造成1点伤害。每回合限使用1次",
}