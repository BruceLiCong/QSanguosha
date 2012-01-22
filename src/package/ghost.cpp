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
        }else if(event == CardEffected){
            CardEffectStruct effect = data.value<CardEffectStruct>();
            card = effect.card;
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

class Tuodao: public TriggerSkill{
public:
    Tuodao():TriggerSkill("tuodao"){
        events << SlashMissed;
    }

    virtual bool triggerable(const ServerPlayer *) const{
        return true;
    }
    virtual bool trigger(TriggerEvent, ServerPlayer *player, QVariant &data) const{
        SlashEffectStruct effect = data.value<SlashEffectStruct>();

        if(effect.to->hasSkill("tuodao") && effect.to->getPhase() == Player::NotActive)
            effect.to->getRoom()->askForUseCard(effect.to, "slash", "@askforslash");

        return false;
    }
};

class Xiaoshou:public MasochismSkill{
public:
    Xiaoshou():MasochismSkill("xiaoshou"){

    }

    virtual void onDamaged(ServerPlayer *guihuaxiong, const DamageStruct &damage) const{
        ServerPlayer *from = damage.from;
        Room *room = guihuaxiong->getRoom();
        QVariant data = QVariant::fromValue(from);
        if(from && from->hasEquip() && room->askForSkillInvoke(guihuaxiong, "xiaoshou", data)){
            int card_id = room->askForCardChosen(guihuaxiong, from, "e", "xiaoshou");
            const Card *card = Sanguosha->getCard(card_id);
            room->obtainCard(guihuaxiong, card_id);

            QList<ServerPlayer *> targets = room->getAllPlayers();
            ServerPlayer *target = room->askForPlayerChosen(guihuaxiong, targets, "xiaoshou");
            if(target != guihuaxiong)
                room->moveCardTo(card, target, Player::Hand, false);
            QString choice = room->askForChoice(guihuaxiong, "xiaoshou", "obtain+equip");
            if(choice == "equip")
                room->moveCardTo(card, target, Player::Equip, true);
            room->playSkillEffect(objectName());
        }
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
    guizhangfei->addSkill(new Skill("longyin", Skill::Compulsory));
    guizhangfei->addSkill(new Skill("huxiao", Skill::Compulsory));

    General *guilvbu = new General(this, "guilvbu", "qun", 4);
    guilvbu->addSkill(new Sheji);
    guilvbu->addSkill(new Skill("juelu", Skill::Compulsory));

    General *guiguanyu = new General(this, "guiguanyu", "shu", 4);
    guiguanyu->addSkill(new Wumo);
    guiguanyu->addSkill(new Tuodao);

    General *guihuaxiong = new General(this, "guihuaxiong", "qun", 4);
    guihuaxiong->addSkill(new Xiaoshou);
}

ADD_PACKAGE(Ghost)
