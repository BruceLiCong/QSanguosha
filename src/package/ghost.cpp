#include "ghost.h"
#include "client.h"
#include "engine.h"
#include "carditem.h"
#include "settings.h"
#include "maneuvering.h"
class SuperJuejing: public TriggerSkill{
public:
    SuperJuejing():TriggerSkill("super_juejing"){
        events   <<GameStart << CardLost << PhaseChange <<CardLostDone <<CardGot <<CardDrawn <<AGTaken ;
        frequency = Compulsory;
    }

    virtual int getPriority() const{
        return 2;
    }
    virtual bool trigger(TriggerEvent event, ServerPlayer *player, QVariant &) const{

        if(event == GameStart){
            player->getRoom()->setPlayerMark(player, "Longwei", 1);
            if(player->getMaxHP() < 1)
                player->getRoom()->setPlayerProperty(player, "maxhp", 1);
            return false;
        }
        Room *room = player->getRoom();
        if(event == PhaseChange){
            if(player->getPhase() == Player::Draw)
                return true;
            return false;
        }


        else if(player->getHandcardNum()<4){
                    player->getRoom()->playSkillEffect(objectName());
                    player->drawCards(4-player->getHandcardNum());
        }
        else if(player->getHandcardNum()>4){
                    room->askForDiscard(player, objectName(), 1);
        }

        return false;
    }
};

class Duojian: public TriggerSkill{
public:
    Duojian():TriggerSkill("duojian"){
        events   << PhaseChange ;

    }
    virtual bool trigger(TriggerEvent , ServerPlayer *player, QVariant &) const{
        Room *room = player->getRoom();
        if(player->getPhase() == Player::Start){
            foreach(ServerPlayer *other, room->getOtherPlayers(player)){
                if(other->getWeapon() && other->getWeapon()->objectName() == "qinggang_sword"&& player->askForSkillInvoke(objectName())){
                    player->obtainCard(other->getWeapon());
                    return false;
                }
            }
            foreach(ServerPlayer *players, room->getAlivePlayers()){
                QList<const Card *> judges = players->getCards("j");
                if(judges.isEmpty())
                continue;
                foreach(const Card *judge, judges){
                      if(judge){
                          int judge_id = judge->getEffectiveId();
                          const Card *card = Sanguosha->getCard(judge_id);
                          if(card->inherits("QinggangSword")&& player->askForSkillInvoke(objectName())){
                              player->obtainCard(card);
                              return false;
                         }
                     }
                  }

            }
        }
        return false;
    }
};

class Longyin: public FilterSkill{
public:
    Longyin():FilterSkill("longyin"){

    }

    virtual bool viewFilter(const CardItem *to_select) const{
        return to_select->getCard()->inherits("Slash") && to_select->getCard()->isBlack();
    }

    virtual const Card *viewAs(CardItem *card_item) const{
        const Card *card = card_item->getCard();
        WushenSlash *slash =new WushenSlash(card->getSuit(), card->getNumber());
        slash->addSubcard(card_item->getCard()->getId());
        slash->setSkillName(objectName());

        return slash;
    }
};

class Sheji: public SlashBuffSkill{
public:
    Sheji():SlashBuffSkill("sheji"){
        frequency = Compulsory;
    }

    virtual bool buff(const SlashEffectStruct &effect) const{
        ServerPlayer *player = effect.from;
        Room *room = player->getRoom();
        if(player->getPhase() != Player::Play)
            return false;

        if(effect.to->inMyAttackRange(player)){
            room->playSkillEffect(objectName());
            room->slashResult(effect, NULL);

                return true;
        }

        return false;
    }
};

class Wumo: public TriggerSkill{
public:
    Wumo():TriggerSkill("wumo"){
        events << CardUsed << CardResponsed;

        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent event, ServerPlayer *player, QVariant &data) const{
        const Card *card = NULL;
        if(event == CardUsed){
            CardUseStruct use = data.value<CardUseStruct>();
            card = use.card;
        }
        if(card == NULL)
            return false;

        if(card->inherits("Slash") && player->getPhase() == Player::Play){
            if(player->askForSkillInvoke(objectName(), data))
                player->drawCards(1);
        }

        return false;
    }
};

GhostPackage::GhostPackage()
    :Package("ghost")
{
    General *yixueshenzhaoyun = new General(this, "yixueshenzhaoyun", "god", 1);
    yixueshenzhaoyun->addSkill(new SuperJuejing);
    yixueshenzhaoyun->addSkill("longhun");
    yixueshenzhaoyun->addSkill(new Duojian);

    General *guizhangfei = new General(this, "guizhangfei", "shu", 4);
    guizhangfei->addSkill(new Longyin);
    guizhangfei->addSkill(new Skill("huxiao", Skill::Compulsory));

    General *guilvbu = new General(this, "guilvbu", "qun", 4);
    guilvbu->addSkill(new Sheji);
    guilvbu->addSkill(new Skill("juelu", Skill::Compulsory));

    General *guiguanyu = new General(this, "guiguanyu", "qun", 4);
    guiguanyu->addSkill(new Wumo);
//    guiguanyu->addSkill(new Skill("juelu", Skill::Compulsory));
}

ADD_PACKAGE(Ghost)
