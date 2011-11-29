
--��Ⱥ������.˾��ʦ
--�̲š��������ɫ�ж�����Чǰ����ɴ��һ�ź�ɫ�ƴ���֮��



�������ص�����
--���ܿ� ʲôҲ����
jicai_card=sgs.CreateSkillCard{
name="jicai_effect",
target_fixed=true,
will_throw=false,
}
--��Ϊ�� ����
jicaivs=sgs.CreateViewAsSkill{
name="jicaivs",
n=1,
view_filter=function(self, selected, to_select)        
        if to_select:isRed() then return true  --���Ƽ��� װ��Ҳ�� ��Ҫ���˵�װ����������Ҫ�� and not to_select:isEquiped()
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
        return pattern=="@@jicai" --����Ӧ Ҫ��һ��jicai_card        
end
}
--������
jicai=sgs.CreateTriggerSkill{
        name="jicai",
        events=sgs.AskForRetrial,--��˵����¼�����Ҫcantrigger
        view_as_skill=jicaivs,
        --frequency=sgs.Skill_Compulsory,
        on_trigger=function(self,event,player,data)
                local room=player:getRoom()
                local simashi=room:findPlayerBySkillName(self:objectName())
                local judge=data:toJudge()                --��ȡ�ж��ṹ��        
                simashi:setTag("Judge",data)                --SET����ӵ����TAG
                if (room:askForSkillInvoke(simashi,self:objectName())~=true) then return false end        --ѯ�ʷ��� ����ȥ��

                local card=room:askForCard(simashi,"@@jicai","@jicai",data)                --Ҫ��һ��jicai_card   ������@jicai��ѯ���ַ���     
                if card~=nil then  -- ��������        
                room:throwCard(judge.card) --ԭ�ж��ƶ��� 
--�������Ҫ����������滻������Ӧ�ø�Ϊsimashi:obtainCard(judge.card)
        judge.card = sgs.Sanguosha:getCard(card:getEffectiveId()) --�ж��Ƹ���
        room:moveCardTo(judge.card, nil, sgs.Player_Special) --�ƶ����ж���
            local log=sgs.LogMessage()  --LOG �����Ǹ��ж�ר�õ�TYPE
            log.type = "$ChangedJudge"
            log.from = player
            log.to:append(judge.who)
            log.card_str = card:getEffectIdString()
            room:sendLog(log)
            room:sendJudgeResult(judge) 
                end
                return false --ҪFALSE~~
        end,        
}

