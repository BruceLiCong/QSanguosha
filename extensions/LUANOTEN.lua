module("extensions.LUANOTEN", package.seeall)
extension = sgs.Package("LUANOTEN")
skills={}

William = sgs.General(extension, "William$", "wei",4)


limitcard=sgs.CreateSkillCard{ --限定技技能卡
name="limiteffect",
target_fixed=true,
on_use=function(self,room,source,targets)		--使用时	
	source:loseAllMarks("@chaos") --失去标记 以后就不能用视为了
	--room:broadcastInvoke("animate", "lightbox:$luanwu") 废了
	room:playSkillEffect("luanwu") 
	 for _,p in sgs.qlist(room:getOtherPlayers(source)) do --其它角色
	 		if(p:isAlive()) then
            	room:cardEffect(self, source, p) --此卡的effect对每个角色生效
			 end			
	 end
end,
on_effect=function(self,effect)	--效果
		local room = effect.to:getRoom()
		local players = room:getOtherPlayers(effect.to) --除了生效者本人
		local distance_list=sgs.IntList() --INT型LIST
		local nearest = 1000 
		for _,p in sgs.qlist(players) do
				local distance = effect.to:distanceTo(p)  
				distance_list :append(distance)
				nearest = math.min(nearest, distance)	 --返回最小值			
		end
		local  luanwutargets=sgs.SPlayerList() --生效者本人的乱舞目标
		for var=0,distance_list:length(),1 do 
				if(distance_list:at(var) == nearest and effect.to:canSlash(players:at(var))) then --如果能砍到
                luanwutargets:append(players:at(var)) end --乱舞目标LIST添加这个人
		end		
		local slash=nil --打出的杀
		 if(not luanwutargets:isEmpty() )then --乱舞目标LIST非空
			slash=room:askForCard(effect.to, "slash", "@luanwu-slash")
			if slash==nil then room:loseHp(effect.to,1)  return end --若没打出流失
       		 local toslash=nil
       		 if(luanwutargets:length() == 1) then --若只有一个人
          		  toslash = luanwutargets:first()
       		 else
           		  toslash = room:askForPlayerChosen(effect.to, luanwutargets, "luanwu") --让生效者选一个人砍它
			 end
			 local use=sgs.CardUseStruct()
			 		use.card = slash
			 		use.from = effect.to
			 		local sp=sgs.SPlayerList()
			 		sp:append(toslash)
			 		use.to = sp
			 		room:useCard(use,false)
        else --乱舞目标LIST空了就直接流失
			 room:loseHp(effect.to,1)
		end
end
}

limitvs=sgs.CreateViewAsSkill{
name="limitvs",
n=0,
view_as=function(self, cards)
	if #cards==0 then 
	local acard=limitcard:clone()		
	acard:setSkillName("luanwu")
	return acard end
end,
enabled_at_play=function()
	if sgs.Self:getMark("@chaos")>0 then return true --判断标记
	else return false end
end,
enabled_at_response=function(self,pattern) 
	return false 
end
}

limited=sgs.CreateTriggerSkill{
name="limited",
events=sgs.GameStart, --游戏开始
view_as_skill=limitvs, --添加视为
frequency=sgs.Skill_Limited, --限定
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
    player:gainMark("@chaos",1) --给个标记
end,
}


weimuEX=sgs.CreateTriggerSkill{
name="weimuEX",
events=sgs.CardUsed, 
frequency=sgs.Skill_Compulsory, --锁定
on_trigger=function(self,event,player,data)
	local room=player:getRoom()
    local use=data:toCardUse()
    local card = use.card
	if card==nil then return end
	if  card:inherits("TrickCard") and card:isBlack() and (not card:inherits("Collateral")) then
	   room:throwCard(card)
    return true end
end,
}

BOSS_card=sgs.CreateSkillCard{ --换牌用技能卡
name="BOSScard",
target_fixed=true,
will_throw=false,
once=true,
on_use=function(self,room,source,targets)	
	local t=room:findPlayerBySkillName("BOSS")  --按主公技找主公
	if t:isDead() then return end
	local log=sgs.LogMessage()
	if (room:askForSkillInvoke(source,"BOSS")~=true) then return false end	
	if (room:askForChoice(t,self:objectName(), "yes+no") ~= "yes") then 
	log.from=source
	log.arg=t:objectName()
	log.type ="#BOSSno"				  
	room:sendLog(log)	 
	return true end	  --以上是拒绝
	log.from=source
	log.arg=t:getGeneralName()
	log.type ="#BOSS"				  
	room:sendLog(log)	 
	local to_exchange=t:wholeHandCards()   --主公全部手牌
    local to_exchange2=source:wholeHandCards()  --自己的全部手牌
	room:playSkillEffect("roulin",1) --XXOO
	if not t:isKongcheng() then --不空城就移动
    room:moveCardTo(to_exchange,source,sgs.Player_Hand,false) 
	end	
    room:moveCardTo(to_exchange2,t,sgs.Player_Hand,false) 	
	room:setPlayerFlag(source,"-BOSS_canuse")
end
}

BOSS_vs=sgs.CreateViewAsSkill{ --给魏势力角色的附属视为技能 
name="BOSS_vs",
n=0,
view_filter=function(self,selected,to_select)
	return true
end,
view_as=function(self,cards)
	if #cards==0 then
	local acard=BOSS_card:clone()	
	return acard
	end
end,
enabled_at_play=function()
	return  sgs.Self:hasFlag("BOSS_canuse")
	and sgs.Self:getKingdom()=="wei"
end,
}

BOSSother=sgs.CreateTriggerSkill{ --给魏势力角色的主技能 
name="BOSSother",
view_as_skill=BOSS_vs,
events=sgs.PhaseChange,
on_trigger=function(self,event,player,data)	
	if player:hasSkill("BOSS") then return end
	local room=player:getRoom()		
	if player:getPhase()==sgs.Player_Play then --回合开始可以使用视为技
		room:setPlayerFlag(player,"BOSS_canuse")
	elseif player:getPhase()==sgs.Player_Finish then 	    --回合结束不让使用视为技
		room:setPlayerFlag(player,"-BOSS_canuse")	
	end
end,
}

BOSS=sgs.CreateGameStartSkill{ --主公的主公技
name="BOSS$",
on_gamestart=function(self,player)
	local room=player:getRoom()	
	local log=sgs.LogMessage()
	log.from=player
	log.type ="#BOSSdebug"	--DEBUG输出 可以无视
	for _,sk in sgs.qlist(player:getVisibleSkillList()) do --找到BOSSother技能 从自己的技能栏删除
			  	if (sk:objectName()=="BOSSother") then
			  		table.insert(skills,sk:objectName())		
				    room:detachSkillFromPlayer(player,sk:objectName())						
				end					
	end			  	
	for _,p in sgs.qlist(room:getAlivePlayers()) do --添加到其它角色的技能栏
			if p:objectName()~=player:objectName() then
			log.from=p
			room:sendLog(log)					
			room:attachSkillToPlayer(p,skills[1])
			end
	end
	table.remove(skills)
end,
}


William:addSkill(limited) 
William:addSkill(weimuEX) 
William:addSkill("wansha") 
William:addSkill(BOSSother)
William:addSkill(BOSS) 

sgs.LoadTranslationTable{
	["LUANOTEN"] = "教程10",	
	["William"] = "Dr.威廉",
	["~William"] = "我们··不是好基友吗？",
	["limited"]="乱砍",
	[":limited"]="贾诩从我这偷学的技能！！",
	["weimuEX"]="萎墓",
	[":weimuEX"]="锁定技，当你成为黑色锦囊的目标时，跳过对你的结算并立即弃置该锦囊牌",
	["BOSS"]="基友",
	["#jBOSSdebug"]="%from this time!",
	[":BOSS"]="<b>主公技</b>,其他魏势力角色可在他们各自的出牌阶段与你交换一次手牌（你可以拒绝）.",
	["#BOSS"]="%from发动了技能<b><font color='yellow'>【基友】</font><b>,将与%arg搞基交换所有手牌",
	["#BOSSno"]="%arg拒绝与%from<b><font color='yellow'>搞基</font><b>",	
	["BOSSother"]="基友(换牌)",
	[":BOSSother"]="出牌阶段,你可以与主公交换所有手牌.每回合限一次.",
	["BOSScard"]="基友(换牌)",
	["BOSScard:yes"]="与该角色交换所有手牌",
	["BOSScard:no"]="拒绝",	
}