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

MonsterPackage::MonsterPackage()
    :Package("monster")
{
    General *yaosima = new General(this, "yaosima", "wei", 3);
    yaosima->addSkill(new Zhabing);
    yaosima->addSkill(new Guimou);

    General *yaozhoutai = new General(this, "yaozhoutai", "wu", 4);
    yaozhoutai->addSkill(new Buhui);
}

ADD_PACKAGE(Monster)
