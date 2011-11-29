SKILLNAME=sgs.CreateViewAsSkill{
name="SKILLNAME",
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