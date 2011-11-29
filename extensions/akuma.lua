module("extensions.akuma", package.seeall)

extension = sgs.Package("akuma")




baiquan=sgs.CreateTriggerSkill{

    name="baiquan",
        
        events={sgs.CardLost},
        
                priority=-1,

        frequency=sgs.Skill_Frequent,

        on_trigger = function(self,event,player,data)
                local room=player:getRoom()
                local x = player:getHandcardNum()
                local i = player:getMaxHP()
                        
            
                if (x==0) then
                        room:playSkillEffect("baiquan")

                        local judge=sgs.JudgeStruct()
                        judge.pattern=sgs.QRegExp("(.*):(heart):(.*)")
                        judge.good=false
                        judge.reason=self:objectName()
                        judge.who= player

                        room:judge(judge)
                        if(judge:isGood()) then                            
                                room:setEmotion(player, "good")
                                player:drawCards(i)
                        else
                                room:setEmotion(player, "bad")
                        end
                end       
                local log=sgs.LogMessage()
                log.type ="#baiquan"
                log.arg  =player:getGeneralName()
                room:sendLog(log)
                
        end
}
leia=sgs.General(extension,"leia","wei")
leia:addSkill(baiquan)