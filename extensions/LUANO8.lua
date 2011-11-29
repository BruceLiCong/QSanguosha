
--【群】皇叔.司马师
--继才——任意角色判定牌生效前，你可打出一张红色牌代替之。



本帖隐藏的内容
--技能卡 什么也不干
jicai_card=sgs.CreateSkillCard{
name="jicai_effect",
target_fixed=true,
will_throw=false,
}
--视为技 红牌
jicaivs=sgs.CreateViewAsSkill{
name="jicaivs",
n=1,
view_filter=function(self, selected, to_select)        
        if to_select:isRed() then return true  --红牌即可 装备也行 若要过滤掉装备区的牌则要加 and not to_select:isEquiped()
        else return false end
end,
view_as=function(self, cards)
        if #cards==1 then 
        local acard=jicai_card:clone()        
        acard:addSubcard(cards[1])        
        acard:setSkillName("jicai")
        return acard end
end,
enabled_at_play=function()
        return false        
end,
enabled_at_response=function(self,pattern)
        return pattern=="@@jicai" --仅响应 要求一张jicai_card        
end
}
--主技能
jicai=sgs.CreateTriggerSkill{
        name="jicai",
        events=sgs.AskForRetrial,--听说这个事件不需要cantrigger
        view_as_skill=jicaivs,
        --frequency=sgs.Skill_Compulsory,
        on_trigger=function(self,event,player,data)
                local room=player:getRoom()
                local simashi=room:findPlayerBySkillName(self:objectName())
                local judge=data:toJudge()                --获取判定结构体        
                simashi:setTag("Judge",data)                --SET技能拥有者TAG
                if (room:askForSkillInvoke(simashi,self:objectName())~=true) then return false end        --询问发动 可以去掉

                local card=room:askForCard(simashi,"@@jicai","@jicai",data)                --要求一张jicai_card   别忘了@jicai是询问字符串     
                if card~=nil then  -- 如果打出了        
                room:throwCard(judge.card) --原判定牌丢弃 
--如果是想要鬼道那样的替换回来就应该改为simashi:obtainCard(judge.card)
        judge.card = sgs.Sanguosha:getCard(card:getEffectiveId()) --判定牌更改
        room:moveCardTo(judge.card, nil, sgs.Player_Special) --移动到判定区
            local log=sgs.LogMessage()  --LOG 以下是改判定专用的TYPE
            log.type = "$ChangedJudge"
            log.from = player
            log.to:append(judge.who)
            log.card_str = card:getEffectIdString()
            room:sendLog(log)
            room:sendJudgeResult(judge) 
                end
                return false --要FALSE~~
        end,        
}

