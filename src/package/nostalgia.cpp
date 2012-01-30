#include "standard.h"
#include "skill.h"
#include "wind.h"
#include "client.h"
#include "carditem.h"
#include "engine.h"
#include "nostalgia.h"
#include "standard-skillcards.h"

class MoonSpearSkill: public WeaponSkill{
public:
    MoonSpearSkill():WeaponSkill("moon_spear"){
        events << CardFinished << CardResponsed;
    }

    virtual bool trigger(TriggerEvent event, ServerPlayer *player, QVariant &data) const{
        if(player->getPhase() != Player::NotActive)
            return false;

        CardStar card = NULL;
        if(event == CardFinished){
            CardUseStruct card_use = data.value<CardUseStruct>();
            card = card_use.card;

            if(card == player->tag["MoonSpearSlash"].value<CardStar>()){
                card = NULL;
            }
        }else if(event == CardResponsed){
            card = data.value<CardStar>();
            player->tag["MoonSpearSlash"] = data;
        }

        if(card == NULL || !card->isBlack())
            return false;

        Room *room = player->getRoom();
        room->askForUseCard(player, "slash", "@moon-spear-slash");

        return false;
    }
};

class MoonSpear: public Weapon{
public:
    MoonSpear(Suit suit = Card::Diamond, int number = 12)
        :Weapon(suit, number, 3){
        setObjectName("moon_spear");
        skill = new MoonSpearSkill;
    }
};

class SuperGuanxing: public PhaseChangeSkill{
public:
    SuperGuanxing():PhaseChangeSkill("super_guanxing"){
        frequency = Frequent;
    }

    virtual bool onPhaseChange(ServerPlayer *zhuge) const{
        if(zhuge->getPhase() == Player::Start && zhuge->askForSkillInvoke(objectName()))
        {
            Room *room = zhuge->getRoom();
            room->playSkillEffect("super_guanxing");

            room->doGuanxing(zhuge, room->getNCards(5, false), false);
        }
        return false;
    }
};

class SuperZhiheng: public ViewAsSkill{
public:
    SuperZhiheng():ViewAsSkill("super_zhiheng"){}

    virtual bool viewFilter(const QList<CardItem *> &, const CardItem *) const{
        return true;
    }

    virtual const Card *viewAs(const QList<CardItem *> &cards) const{
        if(cards.isEmpty())
            return NULL;

        ZhihengCard *zhiheng_card = new ZhihengCard;
        zhiheng_card->addSubcards(cards);

        return zhiheng_card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return player->usedTimes("ZhihengCard") < (player->getLostHp() + 1);
    }
};

class SuperFanjian: public ZeroCardViewAsSkill{
public:
    SuperFanjian():ZeroCardViewAsSkill("superfanjian"){

    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->isKongcheng() && ! player->hasUsed("SuperFanjianCard");
    }

    virtual const Card *viewAs() const{
        return new SuperFanjianCard;
    }
};

SuperFanjianCard::SuperFanjianCard(){
    once = true;
}

void SuperFanjianCard::onEffect(const CardEffectStruct &effect) const{
    ServerPlayer *superzhouyu = effect.from;
    ServerPlayer *target = effect.to;
    Room *room = superzhouyu->getRoom();

    int card_id = superzhouyu->getRandomHandCardId();
    const Card *card = Sanguosha->getCard(card_id);
    Card::Suit suit = room->askForSuit(target);

    LogMessage log;
    log.type = "#ChooseSuit";
    log.from = target;
    log.arg = Card::Suit2String(suit);
    room->sendLog(log);
    room->showCard(target, card_id);
    room->getThread()->delay();

    if(card->getSuit() != suit){
        DamageStruct damage;
        damage.card = NULL;
        damage.from = superzhouyu;
        damage.to = target;

        if(damage.from->hasSkill("jueqing")){
            LogMessage log;
            log.type = "#Jueqing";
            log.from = damage.from;
            log.to << damage.to;
            log.arg = QString::number(1);
            room->sendLog(log);
            room->playSkillEffect("jueqing");
            room->loseHp(damage.to, 1);
        }else{
            room->damage(damage);
        }
    }

    target->obtainCard(card);
}

class SuperJuejing: public TriggerSkill{
public:
    SuperJuejing():TriggerSkill("super_juejing"){
        events   <<GameStart << CardLost << PhaseChange <<CardLostDone <<CardGot <<CardDrawnDone <<CardGotDone ;
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


JiedaoCard::JiedaoCard(){
    once = true;
}

bool JiedaoCard::targetFilter(const QList<const Player *> &targets, const Player *to_select, const Player *Self) const{
    return targets.isEmpty() && to_select->getWeapon();
}

class JiedaoViewAsSkill: public ZeroCardViewAsSkill{
public:
    JiedaoViewAsSkill():ZeroCardViewAsSkill("jiedao"){
    }

    virtual const Card *viewAs() const{
        JiedaoCard *card = new JiedaoCard;
        card->setSkillName(objectName());
        return card;
    }

    virtual bool isEnabledAtPlay(const Player *player) const{
        return !player->hasUsed("JiedaoCard");
    }

};

class Jiedao: public TriggerSkill{
public:
    Jiedao():TriggerSkill("jiedao"){
        events  << PhaseChange << CardUsed;
        view_as_skill = new JiedaoViewAsSkill;
    }

    virtual bool trigger(TriggerEvent event, ServerPlayer *player, QVariant &data) const{
        Room *room = player->getRoom();
//        QList<ServerPlayer *> targets = room->getOtherPlayers(player);
        static ServerPlayer *target;
        static const Weapon *weapon;
        if(event == CardUsed && player->getPhase() == Player::Play){
            CardUseStruct use = data.value<CardUseStruct>();
            if(use.card->getSkillName() != "jiedao")
                return false;
 //           foreach(ServerPlayer *other, room->getOtherPlayers(player)){
 //               if(other->getWeapon()){
 //                   targets << other;
 //               }
 //           }
 //           target = room->askForPlayerChosen(player, targets, objectName());
            target = use.to.first();
            weapon = use.to.first()->getWeapon();
            room->moveCardTo(weapon, player, Player::Equip, true);
            room->setPlayerFlag(player, "Jiedaoused");

        }
        else if(event == PhaseChange && player->getPhase() == Player::Finish && player->hasFlag("Jiedaoused")){
            room->moveCardTo(weapon, target, Player::Equip, true);
            room->setPlayerFlag(player, "-Jiedaoused");
        }
        return false;
    }
};

NostalgiaPackage::NostalgiaPackage()
    :Package("nostalgia")
{
    General *wuxing_zhuge = new General(this, "wuxingzhuge", "shu", 3);
    wuxing_zhuge->addSkill(new SuperGuanxing);
    wuxing_zhuge->addSkill("kongcheng");
    wuxing_zhuge->addSkill("#kongcheng-effect");

    General *zhiba_sunquan = new General(this, "zhibasunquan$", "wu", 4);
    zhiba_sunquan->addSkill(new SuperZhiheng);
    zhiba_sunquan->addSkill("jiuyuan");

    General *super_zhouyu = new General(this, "superzhouyu", "wu", 3);
    super_zhouyu->addSkill("yingzi");
    super_zhouyu->addSkill(new SuperFanjian);

    General *yixueshenzhaoyun = new General(this, "yixueshenzhaoyun", "god", 1);
    yixueshenzhaoyun->addSkill(new SuperJuejing);
    yixueshenzhaoyun->addSkill("longhun");
    yixueshenzhaoyun->addSkill(new Duojian);

    General *longzhouyu = new General(this, "longzhouyu", "wu", 3);
    longzhouyu->addSkill("yingzi");
    longzhouyu->addSkill(new Jiedao);

    addMetaObject<SuperFanjianCard>();
    addMetaObject<JiedaoCard>();

}

NostalgiaCardPackage::NostalgiaCardPackage()
    :Package("nostalgia_cards")
{
    Card *moon_spear = new MoonSpear;
    moon_spear->setParent(this);

    type = CardPack;
}

ADD_PACKAGE(Nostalgia)
ADD_PACKAGE(NostalgiaCard)
