module("extensions.R2", package.seeall)
extension = sgs.Package("R2")

renzhu=sgs.CreateTriggerSkill{
name="renzhu",
events=sgs.PhaseChange,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local liubang=room:findPlayerBySkillName(self:objectName())
	if liubang:getPhase()==sgs.Player_Play then	    
		if(room:askForSkillInvoke(liubang,self:objectName()) ~=true) then return false end
			local target = room:askForPlayerChosen(liubang, room:getOtherPlayers(liubang), "@renzhu")
			local x = target:getHandcardNum()
            if(x == 0) then return false end	
            local to_exchange=target:wholeHandCards()  
            local to_exchange2= liubang:wholeHandCards()  
            room:moveCardTo(to_exchange,liubang, sgs.Player_Hand, true) 
            room:moveCardTo(to_exchange2,target, sgs.Player_Hand, true) 			
			local log=sgs.LogMessage()
			log.from =liubang
			log.type ="#renzhu"
		    log.arg  =target:getGeneralName()
			room:sendLog(log)
	end
	end,
}
dafeng=sgs.CreateTriggerSkill{
	name="dafeng$",
	events=sgs.CardUsed,
	priority=2,
	can_trigger=function(target)
	return true
	end,
	on_trigger=function(self,event,player,data)
	if event==sgs.CardUsed then 	    
		local use=data:toCardUse()
		local card = use.card
		local room=player:getRoom()
		local liubang=room:findPlayerBySkillName(self:objectName())
		if not use.from:getKingdom()=="shu" then return false end		
		if use.from:objectName()== liubang:objectName() then return  false end
		if not card:isNDTrick() then return false end		
	    if (room:askForChoice(player, self:objectName(), "agree+ignore") ~= "agree") then return false end
		if (room:askForSkillInvoke(liubang,self:objectName())~=true) then return false end
        use.from=liubang		
		local log=sgs.LogMessage()
		log.type ="#dafeng"
		log.from=liubang
		log.arg  =player:getGeneralName()
		log.arg2  =use.card:objectName()
		room:sendLog(log)
		data:setValue(use)
        return false		
	end
	end,
}
yunchou_card=sgs.CreateSkillCard{
name="yunchou_effect",
once=true,
will_throw=false,
filter=function(self,targets,to_select)
	if not to_select:hasFlag("yunchou_source") then return false
	else return true end
end,
on_effect=function(self,effect)
	effect.to:obtainCard(self);
end
}

yunchou_viewAsSkill=sgs.CreateViewAsSkill{
name="yunchou_viewAs",
n=1,
view_filter=function(self, selected, to_select)
	if to_select:isEquipped() then return false
	else return true end
end,
view_as=function(self, cards)
	if #cards==0 then return nil end
	local ayunchou_card=yunchou_card:clone()	
	ayunchou_card:addSubcard(cards[1])	
	return ayunchou_card
end,
enabled_at_play=function()
	--return true
	return false
end,
enabled_at_response=function(self,pattern)
	if pattern=="@yunchou" then return true
	else return false end
end
}

yunchou=sgs.CreateTriggerSkill{
	name="yunchou",
	events={sgs.TurnStart},
	view_as_skill=yunchou_viewAsSkill,
	priority=2,
	can_trigger=function(target)
	return true
	end,
	--frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if not event==sgs.TurnStart then return false end		
		local room=player:getRoom()
		local zhangliang=room:findPlayerBySkillName(self:objectName())
		if(player:objectName()==zhangliang:objectName()) then return false end
		if (room:askForSkillInvoke(zhangliang,self:objectName())~=true) then return false end
		local prompt="@@yunchou"
		room:setPlayerFlag(player,"yunchou_source")
		local card=room:askForUseCard(zhangliang,"@yunchou",prompt)
		room:setPlayerFlag(player,"-yunchou_source")
        if card then
			--room:setPlayerFlag(player,"-yunchou_source")		
			room:doGuanxing(zhangliang, room:getNCards(3), false)
			return false
		end
	end
}

mingzhe=sgs.CreateTriggerSkill{
	name="mingzhe",
	events={sgs.Predamaged},
	priority=3,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if not event==sgs.Predamaged then return false end
		local damage=data:toDamage()
		local room=player:getRoom()
		local zhangliang=room:findPlayerBySkillName(self:objectName())
		if (room:askForSkillInvoke(player,self:objectName())~=true) then return false end
		local x=0
		while x<damage.damage do
		   room:doGuanxing(player, room:getNCards(3), false)	
		   player:drawCards(1)
           x=x+1		   
		end
		return false
	end
}

yishan=sgs.CreateViewAsSkill{
name="yishan",
n=2,
view_filter=function(self, selected, to_select)
	if #selected ==0 then return not to_select:isEquipped() end
	if #selected == 1 then 
			local cc = selected[1]:getSuit()
			return (not to_select:isEquipped()) and to_select:getSuit() == cc
	else return false
	end	
end,
view_as=function(self, cards)
	if #cards==0 then return nil end	
	if #cards==2 then	
		local ys_card=sgs.Sanguosha:cloneCard("archery_attack",sgs.Card_NoSuit, 0)	
		ys_card:addSubcard(cards[1])	
		ys_card:addSubcard(cards[2])
		ys_card:setSkillName(self:objectName())
		return ys_card end	
end,
enabled_at_play=function()
	return true	
end,
enabled_at_response=function(self,pattern)	
	return false 
end
}
baijiang=sgs.CreateTriggerSkill{
	name="baijiang",
	events={sgs.TurnStart},
	priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)
	if player:hasFlag("baijiang_wake") then return false end
	if event==sgs.TurnStart then  		
		local room=player:getRoom()
		if(player:getHp()==1) then
			local log=sgs.LogMessage()
			log.type ="#baijiang"
			log.from=player		
			room:sendLog(log)
			room:setPlayerFlag(player,"baijiang_wake")
			room:loseMaxHp(player,2)
			return false
		end
	end
	end
}
dianbing=sgs.CreateTriggerSkill{		
	name      = "dianbing",	
	isVisible =function() return false end,
	events={sgs.DrawNCards,sgs.PhaseChange}, 
	on_trigger=function(self,event,player,data)	
		local room=player:getRoom()	
		if player:hasFlag("baijiang_wake") then
			if event==sgs.DrawNCards then 			
				data:setValue(data:toInt()+2)
				local log=sgs.LogMessage()
				log.type ="#dianbingdraw"
				log.from=player		
				room:sendLog(log)
			elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Discard) then							
				local x = player:getHp()
				local y = player:getHandcardNum()				
				if y-x>1 then room:askForDiscard(player,"dianbing",y-x-1,false,false) 				
				return true
				else return false
				end			
			end
		end
	end
}
liangdao=sgs.CreateTriggerSkill{
name="liangdao",
can_trigger=function(target)
return true
end,
events=sgs.PhaseChange,
on_trigger=function(self,event,player,data)
	local room=player:getRoom()	
	local xiaohe=room:findPlayerBySkillName(self:objectName())
	if player:getPhase()==sgs.Player_Finish then 	    
		--if(room:askForSkillInvoke(xiaohe,self:objectName()) ~=true) then return false end
			local x = player:getMaxHP()
			local y = player:getHandcardNum()
			if y<=1 then 
					if (room:askForSkillInvoke(xiaohe,self:objectName())~=true) then return false end
					local log=sgs.LogMessage()
					log.type ="#liangdao"
					log.from=player		
					room:sendLog(log)
					if (x-y<=5) then 
						player:drawCards(x-y)
					else player:drawCards(5) end
				else return false
			end			
	end
	end,
}
jiulv=sgs.CreateTriggerSkill{
	name="jiulv",
	events={sgs.CardEffected},
	--frequency=sgs.Skill_Frequent,
	on_trigger=function(self,event,player,data)
		local effect=data:toCardEffect()
		local room=player:getRoom()
		if not effect.card:inherits("Slash") then return end		
		if not room:askForSkillInvoke(player,self:objectName()) then return end
		local log=sgs.LogMessage()
		log.type ="#jiulv"
		log.arg  =player:getGeneralName()
		room:sendLog(log)
		local x=player:getLostHp()+1
		player:drawCards(x)
		room:askForDiscard(player,"jiulv",x,false,false) 
	end
}
zhuxin=sgs.CreateTriggerSkill{
	name="zhuxin",
	events={sgs.PhaseChange},
	priority=2,
	on_trigger = function(self,event,player,data)
	local room=player:getRoom()
	local log=sgs.LogMessage()
	log.from=player	
	if (event==sgs.PhaseChange) then
		if not player:hasSkill(self:objectName()) then return end	
		if player:getPhase()~=sgs.Player_Play then return end
		if not room:askForSkillInvoke(player,self:objectName()) then return end
			local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "zhuxin")	
			while(target:getHandcardNum()==0) do
					target = room:askForPlayerChosen(player, room:getOtherPlayers(player), "zhuxin")
			end
			local card_id=room:askForCardChosen(target,target,"h",self:objectName())
			local card=sgs.Sanguosha:getCard(card_id)
			log.type = "#zhuxincard"
			log.arg2= card:getSuitString()
			log.arg = target:getGeneralName()
			room:sendLog(log)
			local suit=card:getSuitString()
			suit="."..suit:sub(1,1):upper()
			room:setPlayerFlag(player,"zhuxin_source")
			local zx=room:askForUseCard(player,suit,"@zhuxin:"..suit)
			if zx then 
					local damage=sgs.DamageStruct()
					damage.damage=1
					damage.from=player
					damage.to=target
					damage.nature=sgs.DamageStruct_Normal
					damage.chain=false					
					log.type = "#zhuxin"
					log.arg = target:getGeneralName()
					room:sendLog(log)
					room:damage(damage)
					room:setPlayerFlag(player,"-zhuxin_source")
			end
		end			
	end	
}

yanran=sgs.CreateTriggerSkill{		
	name      = "yanran",
	events={sgs.Predamage,sgs.PhaseChange}, 
	--priority=2,
	frequency=sgs.Skill_Compulsory,
	on_trigger=function(self,event,player,data)	
		local room=player:getRoom()	
		local lvzhi=room:findPlayerBySkillName(self:objectName())
		local log=sgs.LogMessage()
		log.from=lvzhi	
		if player:hasSkill(self:objectName()) then return end
		local to_discard=0
			if(event==sgs.Predamage) and (player:getPhase()==sgs.Player_Play)then
				local damage=data:toDamage()
				to_discard=to_discard+damage.damage
				if not room:askForSkillInvoke(lvzhi,self:objectName()) then return end
				room:setPlayerFlag(player,"yanran_source")
				return false			
			elseif (event==sgs.PhaseChange) and (player:getPhase()==sgs.Player_Discard) then
					if not player:hasFlag("yanran_source") then return end
					if not room:askForSkillInvoke(lvzhi,self:objectName()) then return end
					local x = player:getHp()
					local y = player:getHandcardNum()
					local z=(to_discard/2)+1					
					log.type = "#yanran"
					log.arg = player:getGeneralName()
					--log.arg2=sgs.qstring(to_discard)
					room:sendLog(log)
					if (y<=x) then room:askForDiscard(player,"yanran",z,false,false)
						room:setPlayerFlag(player,"-yanran_source")
						return true
					elseif(y-x<=z)  then room:askForDiscard(player,"yanran",z,false,false) 
						room:setPlayerFlag(player,"-yanran_source")
						return true
					elseif(y-x>z)  then return false
					end
					
			end
	end,
	can_trigger=function()
		return true
	end
}

--刘邦
liubang = sgs.General(extension, "liubang", "shu")
liubang:addSkill(renzhu) 
liubang:addSkill(dafeng)
--张良
zhangliang = sgs.General(extension, "zhangliang", "shu",3)
zhangliang:addSkill(yunchou)
zhangliang:addSkill(mingzhe)
--韩信
hanxin = sgs.General(extension, "hanxin", "shu")
hanxin:addSkill(yishan) --仅视为万箭齐发 类似蛊惑的技能太复杂
hanxin:addSkill(baijiang)
hanxin:addSkill(dianbing)
--萧何
xiaohe = sgs.General(extension, "xiaohe", "shu",3)
xiaohe:addSkill(liangdao)
xiaohe:addSkill(jiulv)

lvzhi = sgs.General(extension, "lvzhi", "shu",3)
lvzhi:addSkill(zhuxin)
lvzhi:addSkill(yanran)

sgs.LoadTranslationTable{
	["R2"] = "R2零件包",
	
	["liubang"] = "刘邦",
	["renzhu"]="人主",
	[":renzhu"]="出牌阶段,你可以指定一名角色,该角色将所有手牌与你交换,每阶段限用一次.",
	["#renzhu"]="由于%from的【人主】 %arg与之交换了所有手牌",	
	["dafeng"]="大风",	
	[":dafeng"]="<b>主公技</b>当其他蜀势力角色使用非延时锦囊时,(在结算前)可令你成为该锦囊的使用者(你可以拒绝).",	
	["#dafeng"]="%arg使用了【大风】，令%from成为了%arg2的使用者",
	["dafeng:agree"] = "让刘邦成为这张锦囊的使用者",
	["dafeng:ignore"] = "不发动大风",
	
	["zhangliang"] = "张良",
	["yunchou"] = "运筹",
	["yunchou_effect"]="运筹",
	["@yunchou"] = "运筹",
	["@@yunchou"] = "请使用一张手牌以运筹",
	[":yunchou"] = "任意其他角色回合开始阶段,你可以交给该角色一张手牌,然后观看牌堆顶的三张牌\
	将其中任意数量的牌以任意顺序置于牌堆顶,其余以任意顺序置于牌堆底.",
	["mingzhe"] = "明哲",
	[":mingzhe"] = "你每受到1点伤害,可以观看牌堆顶的三张牌,并调整其顺序,然后你摸一张牌。",
	
	["hanxin"] = "韩信",
	["yishan"] = "益善",
	[":yishan"] = "出牌阶段,你可以将两张相同花色的手牌当作任意基本牌或非延时锦囊使用或打出,每阶段限用一次",
	["baijiang"] = "拜将",
	[":baijiang"] = "<b>觉醒技</b>，回合开始阶段，若你的体力为1，你须减2点体力上限\
	并永久获得技能“点兵”（摸牌阶段，你可以额外摸两张牌，你的手牌上限+1）。",
	["#baijiang"] = "%from的觉醒技【拜将】被触发，【点兵】技能开始生效",
	["dianbing"] = "点兵",
	[":dianbing"] = "摸牌阶段，你可以额外摸两张牌，你的手牌上限始终+1",
	["#dianbingdraw"] = "%from的【点兵】被触发，摸牌阶段将额外摸2张牌",
	
	
	["xiaohe"] = "萧何",
	["liangdao"] = "粮道",
	[":liangdao"] = "任意角色的回合结束阶段,若其手牌数不超过一,你可以令该角色将手牌补至其体力上限的张数(最多补至五张)",
	["#liangdao"] = "由于【粮道】的效果，%from的手牌将补充至其体力上限的张数",
	["jiulv"] = "九律",
	[":jiulv"] = "当你成为【杀】的目标时,你可以摸X张牌,然后弃等量的手牌,X为你已损失的体力值+1",
	
	["lvzhi"] = "吕雉",
	["zhuxin"] = "诛心",
	[":zhuxin"] ="出牌阶段开始时,你可以指定一名角色展示一张手牌的花色\
然后你可以使用一张与展示牌相同花色的手牌,若如此做,视为你对其造成1点伤害\
★牌的花色展示仅会在游戏日志窗出现\
★若在其展示完毕你不能打出同花色的牌,则技能不会生效",
	["#zhuxin"]="%from的【诛心】成功生效，%arg将受到1点伤害",
	["#zhuxincard"]="由于%from的【诛心】,%arg展示了一张 %arg2 牌",
	["@zhuxin"] = "请弃掉一张与展示牌同花色的手牌",
	["yanran"] = "晏然",
	[":yanran"] = "<b>锁定技</b>,若其他角色在各自的回合中造成来源于该角色的伤害\
该角色弃牌阶段须至少弃X张牌,X为其本回合中所造成的伤害值的一半(向上取整)",
	["#yanran"] = "%from的【晏然】被触发,%arg弃牌时将至少弃掉其在本回合造成伤害值的一半",
	
	["designer:liubang"]="roxiel",	
	["designer:zhangliang"]="roxiel",
	["designer:hanxin"]="roxiel",
	["designer:xiaohe"]="roxiel",
	["designer:lvzhi"]="roxiel",
}