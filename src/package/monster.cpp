#include "monster.h"
#include "skill.h"
#include "standard.h"
#include "clientplayer.h"
#include "carditem.h"
#include "engine.h"

class Zhabing: public TriggerSkill{
public:
    Zhabing():TriggerSkill("zhabing"){
        events << PhaseChange << Predamaged;
    }

    virtual bool trigger(TriggerEvent event, ServerPlayer *yaosima, QVariant &data) const{
        Room *room = yaosima->getRoom();

        if(event == PhaseChange && yaosima->getPhase() == Player::Finish){
            if(!room->askForSkillInvoke(yaosima, objectName()))
                return false;
            room->loseHp(yaosima);
            yaosima->gainMark("@sick", 1);;
        }
        else if(event == PhaseChange && yaosima->getPhase() == Player::Start){
            if(yaosima->getMark("@sick"))
                yaosima->loseMark("@sick", 1);;
        }
        else if(event == Predamaged){
            if(yaosima->getMark("@sick"))
                return true;
        }
        return false;
    }
};

class Guimou: public DrawCardsSkill{
public:
    Guimou():DrawCardsSkill("guimou"){
        frequency = Compulsory;
    }

    virtual int getDrawNum(ServerPlayer *player, int n) const{
        return n + player->getLostHp();
    }
};

class Buhui: public ProhibitSkill{
public:
    Buhui():ProhibitSkill("buhui"){

    }

    virtual bool isProhibited(const Player *, const Player *, const Card *card) const{
        return card->inherits("Slash");
    }
};

class Zhongyi: public TriggerSkill{
public:
    Zhongyi():TriggerSkill("zhongyi"){
        events << CardLost;

        frequency = Frequent;
    }

    virtual bool trigger(TriggerEvent , ServerPlayer *yaolingtong, QVariant &data) const{
        if(yaolingtong->isKongcheng()){
            CardMoveStar move = data.value<CardMoveStar>();

            if(move->from_place == Player::Hand){
                Room *room = yaolingtong->getRoom();
                if(room->askForSkillInvoke(yaolingtong, objectName())){
                    room->playSkillEffect(objectName());

                    yaolingtong->drawCards(yaolingtong->getHp());
                }
            }
        }

        return false;
    }
};

class Xieqin: public TriggerSkill{
public:
    Xieqin():TriggerSkill("xieqin"){
        events << Damage;
    }

    virtual bool trigger(TriggerEvent , ServerPlayer *chengyu, QVariant &data) const{
        DamageStruct damage = data.value<DamageStruct>();

        if(chengyu->askForSkillInvoke(objectName(), data)){
            Room *room = chengyu->getRoom();
            room->playSkillEffect(objectName());
            QList<ServerPlayer *> players = room->getOtherPlayers(damage.to);
            ServerPlayer *target = room->askForPlayerChosen(chengyu, players, objectName());
            int to_throw = room->askForCardChosen(chengyu, target, "he", objectName());
            room->throwCard(to_throw);
        }

        return false;
    }
};

class Shiwei: public TriggerSkill{
public:
    Shiwei():TriggerSkill("shiwei"){
        events << StartJudge << FinishJudge;
    }

    virtual bool triggerable(const ServerPlayer *target) const{
        return target->getRoom()->findPlayerBySkillName(objectName());
    }

    virtual bool trigger(TriggerEvent event, ServerPlayer *player, QVariant &data) const{
        Room *room = player->getRoom();
        JudgeStar judge = data.value<JudgeStar>();
        ServerPlayer *chengyu = room->findPlayerBySkillName(objectName());
        static Card::Suit suit;

        if(event == StartJudge && chengyu->askForSkillInvoke(objectName())){
            suit = room->askForSuit(chengyu);
        }
        else if(event == FinishJudge){
            CardStar card = judge->card;
            if(suit == card->getSuit())
                chengyu->drawCards(1);
        }

        return false;
    }
};

MonsterPackage::MonsterPackage()
    :Package("monster")
{
    General *yaosima = new General(this, "yaosima", "wei", 3);
    yaosima->addSkill(new Zhabing);
    yaosima->addSkill(new Guimou);

    General *yaozhoutai = new General(this, "yaozhoutai", "wu", 4);
    yaozhoutai->addSkill(new Buhui);

    General *yaolingtong = new General(this, "yaolingtong", "wu", 4);
    yaolingtong->addSkill(new Zhongyi);

    General *chengyu = new General(this, "chengyu", "wei", 3);
    chengyu->addSkill(new Xieqin);
    chengyu->addSkill(new Shiwei);

}

ADD_PACKAGE(Monster)
