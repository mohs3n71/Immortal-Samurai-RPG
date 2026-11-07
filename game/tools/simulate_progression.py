"""Progression simulator (D-085, re-tuned for D-092): how strong can Kaze get in a given time?

Models the game rules at swing resolution (one swing per 0.7 s for everyone):
combo multipliers 1,1,1,2; falls give +1 max health and +(1 + Blood level)
damage and refill on the spot; knight health 6 x 1.6^(L-1); EVERY enemy hits
for 1 + Plague level (D-092); the Reaper halves max health every 20 s; hero
levels +1% damage (soldier experience is left out: the knights are faster).

The best strategy found: visit the Reaper whenever he is ready, and keep the
two knights at the same level (Plague first when Blood is ahead), because a
higher enemy hit and lower max health both mean more falls.

The boss check is "can he deal the boss's health within one 30 s window?"
(falls during the window are simulated too).

Usage: python3 simulate_progression.py
"""
import copy

INTERVAL = 0.7
COMBO = [1, 1, 1, 2]
FIGHT_SECONDS = 30.0
REAPER_WALK = 4.0      # seconds each way between the knights and the Reaper
REAPER_COOLDOWN = 20.0
KNIGHT_RESPAWN = 1.8

# Region boss sizing, mirrored in scripts/enemies/enemy_roster.gd.
BOSS_HEALTH_AT_75 = 3260000.0
BOSS_HEALTH_EXPONENT = 1.16
BOSS_HEALTHS = [1110000.0, 3260000.0, 6510000.0]   # D-101: regions 1-3 (30, 45, 60 min each)


def knight_health(level):
    return round(6 * 1.6 ** (level - 1))


class Hero:
    def __init__(self):
        self.max_health = 1
        self.health = 1
        self.damage = 1
        self.level = 1
        self.blood = 0
        self.plague = 0
        self.time = 0.0
        self.combo = 0
        self.reaper_ready = 0.0

    def effective(self):
        return self.damage * (1 + 0.01 * (self.level - 1))

    def enemy_hit(self):
        return 1 + self.plague

    def swing(self):
        multiplier = COMBO[self.combo % 4]
        self.combo += 1
        return self.effective() * multiplier

    def take_hit(self):
        self.health -= self.enemy_hit()
        if self.health <= 0:
            self.max_health += 1
            self.damage += 1 + self.blood
            self.health = self.max_health


KNIGHT_WINDOW = 30.0   # D-101: knights refill their health 30 s into a fight


def fight_knight(hero, which, max_windows=40):
    """Returns False when the knight could not be beaten within max_windows."""
    level = (hero.blood if which == "blood" else hero.plague) + 1
    health = knight_health(level)
    window = 0.0
    windows = 0
    while health > 0:
        hero.time += INTERVAL
        window += INTERVAL
        health -= hero.swing()
        if health > 0:
            hero.take_hit()
            if window >= KNIGHT_WINDOW:
                window -= KNIGHT_WINDOW
                windows += 1
                health = knight_health(level)
                if windows >= max_windows:
                    return False
    if which == "blood":
        hero.blood += 1
    else:
        hero.plague += 1
    hero.time += KNIGHT_RESPAWN
    return True


def visit_reaper(hero):
    if hero.time < hero.reaper_ready:
        return
    hero.time += REAPER_WALK
    hero.max_health = max(hero.max_health // 2, 1)
    hero.health = min(hero.health, hero.max_health)
    hero.reaper_ready = hero.time + REAPER_COOLDOWN
    hero.time += REAPER_WALK


def best_strategy(hero):
    """D-101: try the lower knight for one 30 s window; if he refills, switch
    to the other one (still falling and growing all the while)."""
    visit_reaper(hero)
    first = "plague" if hero.plague < hero.blood else "blood"
    if not fight_knight(hero, first, 1):
        fight_knight(hero, "blood" if first == "plague" else "plague", 1)


def boss_window_damage(hero):
    """Damage dealt in one 30 s boss window, falls included."""
    trial = copy.copy(hero)
    trial.health = trial.max_health
    total = 0.0
    for _ in range(int(FIGHT_SECONDS / INTERVAL)):
        total += trial.swing()
        trial.take_hit()
    return total


def region_minutes(region):
    """D-096: region n takes 15 x (n + 1) minutes: 30, 75, 135, 210 ... min in total."""
    return 15 * (region * (region + 1) // 2 + region)


def boss_health(region):
    if region <= len(BOSS_HEALTHS):
        return round(BOSS_HEALTHS[region - 1])
    return round(BOSS_HEALTH_AT_75 * (region_minutes(region) / 75.0) ** BOSS_HEALTH_EXPONENT)


def earliest_kill(region, limit_minutes):
    target = boss_health(region)
    hero = Hero()
    while hero.time < limit_minutes * 60:
        best_strategy(hero)
        if boss_window_damage(hero) >= target:
            return hero.time / 60.0
    return None


if __name__ == "__main__":
    hero = Hero()
    marks = [5, 10, 20, 30, 60, 120, 180, 360]
    index = 0
    while index < len(marks):
        best_strategy(hero)
        while index < len(marks) and hero.time >= marks[index] * 60:
            print("%3d min: 30 s boss damage %10.0f  damage %8.0f  max health %4d  Blood Lv %2d  Plague Lv %2d" % (
                marks[index], boss_window_damage(hero), hero.effective(), hero.max_health, hero.blood + 1, hero.plague + 1))
            index += 1
    for region in (1, 2, 3, 4):
        minute = earliest_kill(region, region_minutes(region) * 3)
        print("region %d boss: health %d, target %d min, earliest kill %s" % (
            region, boss_health(region), region_minutes(region), "%.0f min" % minute if minute else "none"))
