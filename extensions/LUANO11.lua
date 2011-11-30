--����EX
askedtmp={} --����һ��TABLE
kanpoex=sgs.CreateViewAsSkill{
name="kanpoex",
n=1,
view_filter=function(self, selected, to_select)
        return to_select:isBlack() --��ɫ�� ����װ��
end,
view_as=function(self, cards)
        if #cards==1 then 
        local acard=sgs.Sanguosha:cloneCard(askedtmp[1],cards[1]:getSuit(),cards[1]:getNumber()) --��¡�洢�Ŀ�������
        acard:addSubcard(cards[1])
    acard:setSkillName(self:objectName())     
        return acard
        end
end,
enabled_at_play=function()
        return false        
end,
enabled_at_response=function(self,player,pattern)  --ע�����������֮ǰ���˲�����·
    if #askedtmp==1 then table.remove(askedtmp) end --������TABLE
   table.insert(askedtmp,pattern) --����Ҫ��Ŀ�������
   return not player:isKongcheng()   and( pattern=="slash" or pattern=="jink" or pattern=="peach") --�ǿճ���Ҫ��ɱ������ʱ���� 
--���������չ ���ǲ�������и�ɻ�������
end
}
luahujia=sgs.CreateTriggerSkill{
        name="luahujia$",
        events={sgs.CardAsked},        
        on_trigger=function(self,event,player,data)
        local room=player:getRoom()
        local log=sgs.LogMessage()
         if( not pattern == "jink") then return end
         local lieges = room:getLieges("wei", player)
         if (room:askForSkillInvoke(player,self:objectName())~=true) then return end
         room:playSkillEffect("hujia")
         for _,p in sgs.qlist(lieges) do                         
            if( room:askForChoice(p, objectName(), "accept+ignore") ~= "ignore") then             
                   local jink=room:askForCard(p, "jink", "@hujia-jink:"..player:objectName())
                    if(jink~=nil) then
                        room:provide(jink)
                return true
            end        
                         end                         
end
end
}


luaqingguo=sgs.CreateViewAsSkill{
name="luaqingguo",
n=1,
view_filter=function(self, selected, to_select)
        return to_select:isBlack() --��ɫ�� ����װ�� ������������
end,
view_as=function(self, cards)
        if #cards==1 then 
        local acard=sgs.Sanguosha:cloneCard("jink",cards[1]:getSuit(),cards[1]:getNumber()) --��¡�洢�Ŀ�������
        acard:addSubcard(cards[1])
    acard:setSkillName(self:objectName())     
        return acard
        end
end,
enabled_at_play=function()
        return false        
end,
enabled_at_response=function(self,player,pattern)               
   return not player:isKongcheng()   and pattern=="jink"--�ǿճ���Ҫ����������ʱ
end
}