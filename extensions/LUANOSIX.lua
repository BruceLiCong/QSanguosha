module("extensions.LUANOSIX", package.seeall)
extension = sgs.Package("LUANOSIX")

--黑桃无限出杀技能卡
skillnumbersix_card=sgs.CreateSkillCard{
name="skillnumbersix_effect",
target_fixed=true,
will_throw=false,
once=false,
on_use=function(self,room,source,targets)
	if(source:hasFlag("skillnumbersix_spade")) then 
		local card=room:askForCard(source, "slash", "@skillnumbersix_spade",sgs.QVariant())
		if not card then return	end
		local sp=sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(source)) do
			if source:canSlash(p,true) then
            sp:append(p) 
			end  			
		end
		local t = room:askForPlayerChosen(source, sp, "skillnumbersix-spadeslash")
		room:playSkillEffect("skillnumbersix", math.random(1,2))		
		room:cardEffect(card,source, t)
	end
end
}
--红桃距离无限修正技能，感觉-9差不多了
skillnumbersix_heart=sgs.CreateDistanceSkill{
name= "skillnumbersix_heart",
correct_func=function(self,from,to)
	if from:hasFlag("skillnumbersix_heart") and not to:hasFlag("skillnumbersix_fixed")
	then return -9
	else return 0
	end
end
}
--这个VIEWAS是黑桃用的
skillnumbersixvs=sgs.CreateViewAsSkill{
name="skillnumbersixvs",
n=0,
view_filter=function(self, selected, to_select)			
	return false
end,
view_as=function(self, cards)	
	local acard=skillnumbersix_card:clone()	
	acard:setSkillName(self:objectName())		
	return acard	
end,
enabled_at_play=function()
	return --(sgs.Self:hasFlag("skillnumbersix_heart") and not sgs.Self:hasFlag("skillnumbersix_used")) or
    sgs.Self:hasFlag("skillnumbersix_spade") 
    
end,
enabled_at_response=function(self,pattern)	
	return false 
end
}

skillnumbersix=sgs.CreateTriggerSkill{
	name="skillnumbersix",
	events={sgs.TurnStart,sgs.PhaseChange,sgs.SlashProceed},
	view_as_skill=skillnumbersixvs, --黑桃的viewas
	priority=1,
	on_trigger=function(self,event,player,data)
	local room=player:getRoom()
		local log=sgs.LogMessage()
		log.from=player
	if event==sgs.TurnStart then
		if (room:askForSkillInvoke(player,self:objectName())~=true) then return false end
		local judge=sgs.JudgeStruct()
		judge.pattern=sgs.QRegExp("(.*)")
		judge.good=true
		judge.reason="skillnumbersix"
		judge.who=player
		room:judge(judge)		--根据判定牌花色加标记
		if (judge.card:getSuit()==sgs.Card_Heart) then
		     room:setPlayerFlag(player,"skillnumbersix_heart")			 
			 log.type = "#skillnumbersixHeart"
			 room:sendLog(log)				 		 
			 return false						
		elseif	(judge.card:getSuit()==sgs.Card_Diamond) then
			 room:setPlayerFlag(player,"skillnumbersix_diamond")
			 log.type = "#skillnumbersixDiamond"
			 room:sendLog(log)	
			 return false	
		elseif	(judge.card:getSuit()==sgs.Card_Spade) then	
			 room:setPlayerFlag(player,"skillnumbersix_spade")
			 log.type = "#skillnumbersixSpade"
			 room:sendLog(log)		
		return false end	
	elseif (event==sgs.SlashProceed) then
			local effect=data:toSlashEffect()				
			if player:hasFlag("skillnumbersix_diamond")	 then
				room:playSkillEffect("skillnumbersix", 3)
				log.type = "#skillnumbersix_diamond"	
				room:sendLog(log)			
				room:slashResult(effect, nil)   			
				return true
			else return false 
			end
		elseif  player:hasFlag("skillnumbersix_heart") then 
				if (card:inherits("Slash")) then
				room:playSkillEffect("skillnumbersix", 5) 
				return false
				elseif (card:inherits("Snatch") or card:inherits("SupplyShortage")) then  --顺手牵羊和兵粮寸断并不被修正距离
				for _,p in sgs.qlist(use.to) do
				    room:setPlayerFlag(p,"skillnumbersix_fixed") --让skillnumbersix_heart技能不修正距离
					if(player:distanceTo(p)>1) then --未修正时距离大于1
					log.type = "#skillnumbersix_heart"
					room:sendLog(log)
					room:setPlayerFlag(p,"-skillnumbersix_fixed")
					return true	 --使用无效
					end					
				end	
				end	
				return false						
    elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Finish) then	 --回合结束清除标记
        if  player:hasFlag("skillnumbersix_heart") then 
			room:setPlayerFlag(player,"-skillnumbersix_heart")		
		elseif  player:hasFlag("skillnumbersix_diamond")then 
			room:setPlayerFlag(player,"-skillnumbersix_diamond")			
		elseif player:hasFlag("skillnumbersix_spade")then 
			room:setPlayerFlag(player,"-skillnumbersix_spade")
		elseif player:hasFlag("skillnumbersix_used")then 
			room:setPlayerFlag(player,"-skillnumbersix_used")
		end		
	end
	end	
}

gerneralsix=sgs.General(extension,"gerneralsix","wei")
gerneralsix:addSkill(skillnumbersix)
gerneralsix:addSkill(skillnumbersix_heart)

sgs.LoadTranslationTable{
	["LUANOSIX"]="教程6",
	["gerneralsix"]="王老六",
	["skillnumbersix"]="丢屎",
    ["skillnumbersixvs"]="丢屎",			
	["skillnumbersix_heart"]="粪青",
	[":skillnumbersix_heart"]="<b>锁定技</b>,若“丢屎”的判定结果为<b><font color='red'>♥</font></b>,你的攻击范围无限.",	
	[":skillnumbersix"]="—回合开始阶段,你可以进行一次判定,获得与判定结果对应的一项技能直到回合结束：\
	<b><font color='red'>♥</font></b>~攻击范围无限;\
	<b><font color='red'>♦</font></b>~使用的【杀】不可被闪避;\
	♠~可使用任意数量的【杀】",
	["#skillnumbersix_diamond"]="%from的技能“<b><font color='red'>丢屎</font></b>”被触发,目标不可闪避该【杀】",	
	["#skillnumbersix_heart"]="该锦囊的距离并没有被修正",
	["#skillnumbersixHeart"]="本回合%from的攻击范围无限",
	["#skillnumbersixDiamond"]="本回合%from的【杀】不可被闪避",
	["#skillnumbersixClub"]="本回合%from无视其他角色的防具",
	["#skillnumbersixSpade"]="本回合%from可以使用任意数量的【杀】",
	["@skillnumbersix_heart"]="请使用一张【杀】",
	["@skillnumbersix_spade"]="请使用一张【杀】",
	["~gerneralsix"]="天地不仁",
}