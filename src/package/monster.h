#ifndef MONSTER_H
#define MONSTER_H

#include "package.h"
#include "card.h"
#include "skill.h"
#include "standard.h"

class MonsterPackage : public Package{
    Q_OBJECT

public:
    MonsterPackage();
};

#endif // MONSTER_H
