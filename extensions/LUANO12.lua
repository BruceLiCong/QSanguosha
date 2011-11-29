module("extensions.LUANO12", package.seeall)
extension = sgs.Package("LUANO12")


Ruoxuwu = sgs.General(extension, "Ruoxuwu$", "shu",3)


--若愚EX
luaruoyu=sgs.CreateTriggerSkill{
	name="luaruoyu$",
	events=sgs.TurnStart,		
	on_trigger=function(self,event,player,data)
	local room=player:getRoom()
	if  player:hasFlag("luaruoyu_waked")then return end
	local x=player:getHp()
	local m={} 
	for _,p in sgs.qlist(room:getOtherPlayers(player)) do
			table.insert(m,p:getHp())			
	end
	if x>math.min(unpack(m)) then m=nil return end
	local log=sgs.LogMessage()
	log.from =player
	log.type ="#luaruoyu"
	room:sendLog(log)
	room:playSkillEffect("luanwu") 
	room:setPlayerFlag(player,"luaruoyu_waked")
	local recover=sgs.RecoverStruct()
	recover.who=player
	recover.recover=1
	room:recover(player,recover)
	room:setPlayerProperty(player,"maxhp",sgs.QVariant(player:getMaxHP()+2))	
	room:attachSkillToPlayer(player,"jijiang")
 	room:acquireSkill(player, "yinghun")
    room:acquireSkill(player, "yingzi")
    end
}

luaxiangle=sgs.CreateTriggerSkill{
	name="luaxiangle",
	events=sgs.SlashEffected,
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if event==sgs.SlashEffected then 	 	
		local effect=data:toSlashEffect()
		local room=player:getRoom()		
		room:playSkillEffect("xiangle",math.random(1, 2))		
		local log=sgs.LogMessage()
		log.type ="#luaxiangle"
		log.arg=player:getGeneralName()
		log.from =effect.from
		room:sendLog(log)
        for var=1,player:getLostHp(),1 do					
			if(room:askForCard(effect.from, ".basic", "@xiangle-discard", data)) then 
				return false
			else
		end	
			log.type ="#luaxianglenodiscard"
			room:sendLog(log)
			return true
		end
		return false
	end
	end,
}

Ruoxuwu:addSkill(luaruoyu) 
Ruoxuwu:addSkill(luaxiangle) 

sgs.LoadTranslationTable{
	["LUANO12"] = "教程12",	
	["Ruoxuwu"] = "若虚无",
	["~Ruoxuwu"] = "都是虚无 都是浮云",
	["luaruoyu"]="魂淡EX[觉醒技]",
	[":luaruoyu"]="<b>主公技</b>，<b>觉醒技</b>，回合开始阶段，若你的体力是全场最少的(或之一)，你须增加2点体力上限，回复1点体力，并永久获得技能“激将”及“英魂&英姿”。",	
	["#luaruoyu"]="%from的觉醒技【若愚EX】被触发",
	["luaxiangle"]="享乐EX",
	[":luaxiangle"]="<b>锁定技</b>,当其他角色使用【杀】指定你为目标时,须额外弃置X张基本牌,X为你已损失的体力值,否则该【杀】对你无效.",
	["#luaxiangle"]="%from 的技能“<b><font color='yellow'>享乐EX</font></b>”被触发,%arg须额外弃%arg2张牌才能使该【杀】生效",
	["#luaxianglenodiscard"]="%from使用的【杀】对%arg无效",
}