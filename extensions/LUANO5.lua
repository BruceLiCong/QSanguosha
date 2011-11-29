
module("extensions.roxiel", package.seeall)
extension = sgs.Package("roxiel")

--globals--技能所需的全局变量
skills={}
jutarget={}
jugeneral={}
jukingdom={}

pleasecry=sgs.CreateTriggerSkill{
name="pleasecry",
priority=1,
can_trigger=function() --所有玩家的均会触发
return true
end,
events={sgs.TurnStart,sgs.FinishJudge,sgs.PhaseChange,sgs.Death}, 
on_trigger=function(self,event,player,data)
        local room=player:getRoom()        
        local chrysanthemum=room:findPlayerBySkillName(self:objectName()) --技能拥有者       
        local totransfigure="a"        --素将字符串
        local log=sgs.LogMessage()
        if (event==sgs.TurnStart) then --任意角色回合开始 
                 if not (chrysanthemum) then return end
                 if(room:askForSkillInvoke(chrysanthemum,self:objectName()) ~=true) then return false end   --询问技能拥有者发动   
                  local target = room:askForPlayerChosen(chrysanthemum, room:getAlivePlayers(), "pleasecry")      --选目标             
                  if target:getGeneral():isMale() then --以下根据目标武将性别而使用哪种性别的素将
                          totransfigure ="sujiang" --男
                  else totransfigure ="sujiangf" end      --女          
                 local judge=sgs.JudgeStruct() --判定结构体
                 judge.pattern=sgs.QRegExp("(.*)")
                 judge.good=true
                 judge.reason="pleasecry" --判定原因
                 judge.who=target --谁判定
                 room:judge(judge) --判定 ，跳入FinishJudge事件
                 if chrysanthemum:hasFlag("pleasecry_good") then --弃过牌则
                 room:setPlayerFlag(player,"pleasecry_start")                 
                      room:setEmotion(target, "bad")        
                          room:playSkillEffect("lianyu")                                  
                          log.from=chrysanthemum
                          log.arg=target:getGeneralName()
                          log.type="#pleasecry"
                          room:sendLog(log)                                  
                          local datatmp=sgs.QVariant(0)
                      datatmp:setValue(target)                      
                      table.insert(jutarget,datatmp)  --全局TABLE插入目标玩家                        
                          local backkingdom=target:getKingdom() --目标原势力
                          local back=target:getGeneralName() --目标原武将名
                          for _,sk in sgs.qlist(target:getVisibleSkillList()) do
                                          if (sk:objectName()~="spear" and sk:objectName()~="axe") then
                                          table.insert(skills,sk:objectName())      --全局TABLE插入目标原技能                                 
                                        --target:loseSkill(sk:objectName())
                                        room:detachSkillFromPlayer(target,sk:objectName())
                                        end                                        
                          end                          
                          table.insert(jukingdom,backkingdom)--全局TABLE插入目标原势力
                          table.insert(jugeneral,back)--全局TABLE插入目标原武将名
                          local kingdom= backkingdom --以下是变身
                          room:setPlayerProperty(target,"general",sgs.QVariant(totransfigure))
                          room:setPlayerProperty(target,"kingdom",sgs.QVariant(kingdom))
                          room:setPlayerFlag(chrysanthemum,"-pleasecry_good")                                  
                 else                                                                
                           room:setEmotion(chrysanthemum, "bad")        
             end           
        elseif(event==sgs.FinishJudge)        then   --判定结束时
                if not (chrysanthemum) then return end --技能拥有者不存在则返回
                local judge = data:toJudge()
                if(judge.reason == "pleasecry" ) then --判定原因不是此技能就返回
                    local suit=judge.card:getSuitString()      --取判定牌花色字符串                  
                        suit="."..suit:sub(1,1):upper()                        
                        local cz=room:askForCard(chrysanthemum,suit,"@pleasecry",data)--要求打出一张同花色的手牌
                        if cz~=nil then --若打出了
                        room:setPlayerFlag(chrysanthemum,"pleasecry_good") --成功标记                        
                        end                        
                end                        
        elseif ((event==sgs.PhaseChange) and player:getPhase()==sgs.Player_Finish) then --技能发动的回合结束        
                if (not player:hasFlag("pleasecry_start")) then return end     --没有发动技能就返回           
                --if #jutarget==0 then return false end --没有目标则返回
                room:setPlayerFlag(player,"-pleasecry_start")   --清除技能开始标记                     
                local tar=jutarget[1]:toPlayer() --取目标玩家
                local back=jugeneral[1] --取原武将名
                local backkingdom=jukingdom[1]  --取原势力    以下是变回去          
                room:setPlayerProperty(tar,"general",sgs.QVariant(back))
                room:setPlayerProperty(tar,"kingdom",sgs.QVariant(backkingdom))                                
                log.type="#pleasecryend"                
                log.arg=tar:getGeneralName()
                room:sendLog(log)
                for _,s in ipairs(skills) do --技能再绑定回去
                        room:attachSkillToPlayer(tar,s)                        
            end        --以下清空全局TABLE                
                for x=1,#skills,1 do
                table.remove(skills)                
                end                
                table.remove(jutarget)
                table.remove(jugeneral)
                table.remove(jukingdom)                        
                return true        
        elseif (event==sgs.Death) then --技能拥有者死亡时 类似回合结束
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