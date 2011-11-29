
module("extensions.roxiel", package.seeall)
extension = sgs.Package("roxiel")

--globals--���������ȫ�ֱ���
skills={}
jutarget={}
jugeneral={}
jukingdom={}

pleasecry=sgs.CreateTriggerSkill{
name="pleasecry",
priority=1,
can_trigger=function() --������ҵľ��ᴥ��
return true
end,
events={sgs.TurnStart,sgs.FinishJudge,sgs.PhaseChange,sgs.Death}, 
on_trigger=function(self,event,player,data)
        local room=player:getRoom()        
        local chrysanthemum=room:findPlayerBySkillName(self:objectName()) --����ӵ����       
        local totransfigure="a"        --�ؽ��ַ���
        local log=sgs.LogMessage()
        if (event==sgs.TurnStart) then --�����ɫ�غϿ�ʼ 
                 if not (chrysanthemum) then return end
                 if(room:askForSkillInvoke(chrysanthemum,self:objectName()) ~=true) then return false end   --ѯ�ʼ���ӵ���߷���   
                  local target = room:askForPlayerChosen(chrysanthemum, room:getAlivePlayers(), "pleasecry")      --ѡĿ��             
                  if target:getGeneral():isMale() then --���¸���Ŀ���佫�Ա��ʹ�������Ա���ؽ�
                          totransfigure ="sujiang" --��
                  else totransfigure ="sujiangf" end      --Ů          
                 local judge=sgs.JudgeStruct() --�ж��ṹ��
                 judge.pattern=sgs.QRegExp("(.*)")
                 judge.good=true
                 judge.reason="pleasecry" --�ж�ԭ��
                 judge.who=target --˭�ж�
                 room:judge(judge) --�ж� ������FinishJudge�¼�
                 if chrysanthemum:hasFlag("pleasecry_good") then --��������
                 room:setPlayerFlag(player,"pleasecry_start")                 
                      room:setEmotion(target, "bad")        
                          room:playSkillEffect("lianyu")                                  
                          log.from=chrysanthemum
                          log.arg=target:getGeneralName()
                          log.type="#pleasecry"
                          room:sendLog(log)                                  
                          local datatmp=sgs.QVariant(0)
                      datatmp:setValue(target)                      
                      table.insert(jutarget,datatmp)  --ȫ��TABLE����Ŀ�����                        
                          local backkingdom=target:getKingdom() --Ŀ��ԭ����
                          local back=target:getGeneralName() --Ŀ��ԭ�佫��
                          for _,sk in sgs.qlist(target:getVisibleSkillList()) do
                                          if (sk:objectName()~="spear" and sk:objectName()~="axe") then
                                          table.insert(skills,sk:objectName())      --ȫ��TABLE����Ŀ��ԭ����                                 
                                        --target:loseSkill(sk:objectName())
                                        room:detachSkillFromPlayer(target,sk:objectName())
                                        end                                        
                          end                          
                          table.insert(jukingdom,backkingdom)--ȫ��TABLE����Ŀ��ԭ����
                          table.insert(jugeneral,back)--ȫ��TABLE����Ŀ��ԭ�佫��
                          local kingdom= backkingdom --�����Ǳ���
                          room:setPlayerProperty(target,"general",sgs.QVariant(totransfigure))
                          room:setPlayerProperty(target,"kingdom",sgs.QVariant(kingdom))
                          room:setPlayerFlag(chrysanthemum,"-pleasecry_good")                                  
                 else                                                                
                           room:setEmotion(chrysanthemum, "bad")        
             end           
        elseif(event==sgs.FinishJudge)        then   --�ж�����ʱ
                if not (chrysanthemum) then return end --����ӵ���߲������򷵻�
                local judge = data:toJudge()
                if(judge.reason == "pleasecry" ) then --�ж�ԭ���Ǵ˼��ܾͷ���
                    local suit=judge.card:getSuitString()      --ȡ�ж��ƻ�ɫ�ַ���                  
                        suit="."..suit:sub(1,1):upper()                        
                        local cz=room:askForCard(chrysanthemum,suit,"@pleasecry",data)--Ҫ����һ��ͬ��ɫ������
                        if cz~=nil then --�������
                        room:setPlayerFlag(chrysanthemum,"pleasecry_good") --�ɹ����                        
                        end                        
                end                        
        elseif ((event==sgs.PhaseChange) and player:getPhase()==sgs.Player_Finish) then --���ܷ����ĻغϽ���        
                if (not player:hasFlag("pleasecry_start")) then return end     --û�з������ܾͷ���           
                --if #jutarget==0 then return false end --û��Ŀ���򷵻�
                room:setPlayerFlag(player,"-pleasecry_start")   --������ܿ�ʼ���                     
                local tar=jutarget[1]:toPlayer() --ȡĿ�����
                local back=jugeneral[1] --ȡԭ�佫��
                local backkingdom=jukingdom[1]  --ȡԭ����    �����Ǳ��ȥ          
                room:setPlayerProperty(tar,"general",sgs.QVariant(back))
                room:setPlayerProperty(tar,"kingdom",sgs.QVariant(backkingdom))                                
                log.type="#pleasecryend"                
                log.arg=tar:getGeneralName()
                room:sendLog(log)
                for _,s in ipairs(skills) do --�����ٰ󶨻�ȥ
                        room:attachSkillToPlayer(tar,s)                        
            end        --�������ȫ��TABLE                
                for x=1,#skills,1 do
                table.remove(skills)                
                end                
                table.remove(jutarget)
                table.remove(jugeneral)
                table.remove(jukingdom)                        
                return true        
        elseif (event==sgs.Death) then --����ӵ��������ʱ ���ƻغϽ���
                if player:hasSkill("pleasecry") then                
                room:setPlayerFlag(player,"-pleasecry_start")
                for _,p in sgs.qlist(room:getAllPlayers()) do
                        room:setPlayerFlag(p,"-pleasecry_start")                                
                end                        
                local tar=jutarget[1]:toPlayer()
                local back=jugeneral[1]
                local backkingdom=jukingdom[1]
                room:setPlayerProperty(tar,"general",sgs.QVariant(back))
                room:setPlayerProperty(tar,"kingdom",sgs.QVariant(backkingdom))                                        
                log.type="#pleasecryend"                
                log.arg=tar:getGeneralName()
                room:sendLog(log)
                for _,s in ipairs(skills) do                                          
                        room:attachSkillToPlayer(tar,s)                        
            end                        
                for x=1,#skills,1 do
                table.remove(skills)                
                end                
                table.remove(jutarget)
                table.remove(jugeneral)
                table.remove(jukingdom)        
                return false end
        end                        
end,
}