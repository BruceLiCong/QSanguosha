module("extensions.YJCMnostalgia", package.seeall)
extension = sgs.Package("YJCMnostalgia")
shangshih=sgs.CreateTriggerSkill{
	name="shangshih",
	events={sgs.Damaged,sgs.HpRecover,sgs.HpLost,sgs.CardLost},
	priority=-1,
	frequency = sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local lostHp = player:getLostHp()
		if lostHp<=player:getHandcardNum() or lostHp >= player:getMaxHP() then return end
		local move=data:toCardMove()
		if move and not move.from_place==sgs.Player_Hand then return end
		if not room:askForSkillInvoke(player,self:objectName()) then return end
		local log=sgs.LogMessage()
		log.type ="#InvokeSkill"
		room:playSkillEffect("shangshih")
		player:drawCards(lostHp-player:getHandcardNum())
	end,
}

jyuecing=sgs.CreateTriggerSkill{
	name="jyuecing",
	events={sgs.SlashHit,sgs.Predamage},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
		local room=player:getRoom()
		local log=sgs.LogMessage()
		if(room:findPlayerBySkillName("huoshou") and event==sgs.Predamage) then
			local damage=data:toDamage()
			if	(damage.card and damage.card:inherits("SavageAssault")) then
				return false
			end
		end
		log.type = "#TriggerSkill"
		log.from  = player
		log.arg = "jyuecing"
		room:sendLog(log)
		room:playSkillEffect("jyuecing")
		
		if (event==sgs.Predamage) then 
			local damage=data:toDamage()
			room:loseHp(damage.to,damage.damage)
			return true
		elseif(event==sgs.SlashHit)	then
			local slashEffect=data:toSlashEffect()
			if(slashEffect.drank) then
				room:loseHp(slashEffect.to,2)
			else
				room:loseHp(slashEffect.to,1)
			end
			return true
		end 
	end,
}

jhangchunhua=sgs.General(extension, "jhangchunhua", "wei","3",false)
jhangchunhua:addSkill(jyuecing)
jhangchunhua:addSkill(shangshih)

sgs.LoadTranslationTable{
	["YJCMnostalgia"] = "一将成名·怀旧",

	--張春華
	["jhangchunhua"]="张春华",
	["jyuecing"]="绝情",
	[":jyuecing"]="锁定技，你造成的伤害均为体力流失。",
	["shangshih"]="伤逝",
	[":shangshih"]="除弃牌阶段外，每当你的手牌数小于你已损失的体力值时，可立即将手牌数补至等同于你已损失的体力值。",
	["designer:jhangchunhua"] = "樱花闪乱|JZHIEI",
	["cv:jhangchunhua"] = "官方",
	["$jyuecing1"]="你的死活与我何干？",
	["$jyuecing2"]="无来无去，不悔不怨。",
	["$shangshih1"]="无情者伤人，有情者自伤",
	["$shangshih2"]="自损八百，可伤敌一千",
	["~jhangchunhua"] = "怎能如此对我",
}
