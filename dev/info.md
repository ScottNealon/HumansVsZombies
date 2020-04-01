# HUMANS VS ZOMBIES

# TO DO LIST

## Implement realistic movement
#### Description
Currently, humans and zombies move at up to their max run-speed in any direction. In reality, it takes time to change speed and direction. Goal is to implement a movement system that accurately mimics human movement.
#### Challenges
* Finding literature on how quickly people can move in different directions
* Implmenting velocity and acceleration

## Implement realistic targeting
#### Description
Currently, humans can fire in any direction on a dime. In reality, blaster users have a significant disadvantage compared to sock users do to the challenge of shooting behind them. Goal is to implement some form of shooting delay required to aim and shoot.
#### Potential solutions
* Implementing "firing arcs" and "turret heading" that reset every time a shot is fired.

## Implement realistic awareness
#### Description
Currently, humans and zombies are aware of all other humans and zombies. In reality, people have blind spots. Goal is to implement some form of "awareness" for humans.

## Make world resizale with resize-world and set-patch-size
Currently, the world size is fixed to about 1/4 the size of Tech Green. There may be good reason to implement a more dynamic world sizing mechanic.
#### Challenges
* Changes size of world in interface
#### Potential Solutions
* Make categorical world sizes. Don't give those pesty users full control.

## Make humans not stick to walls
Currently, when a human or zombie attemps to run through the edge of the world, it stops them. However, the logic does not then result in them curving around the world edge. 
#### Challenges
* When running towards a cornor, the human should curve around and keep going along the edge of the world. Obvious solutions would likely not result in this behavior.
#### Potential Solutions
* Implementing a "deterance" from being close to the wall
* May use "can-move?"
* Centerwise bias proportional to distance to edge.

## Implement more sophisticated zombie AI
#### Potential Solutions
* Look into "Birb" flocking mechanics 

## Consider swapping how you count humans
#### Description
Currently, there is a count for num-sock-humans and num-blaster-humans. Instead, consider replacing it with num-humans and percent-blaster.
#### Challenges
* If a new human type is added, like hybrid blaster/sock users, it may complicate sliders.

## Implement humans and zombies of variable abillity and methods
#### Description
Currently, all humans and zombies have identical abillities. Implement randomness to abillities and procedures.
#### Potential solutions
* Implement set of "weighting" sliders for different procedures.
* Have some players be "Vets", making a clear distinction between low and high tier.
* Alternativly, classify the top 20% of players as vets.

# MODEL DESCRIPTION

This model simulates the popular campus game Humans vs Zombies. The model is intended to simulate a single fight between the Humans and Zombies.

## Quick Start

The model starts out unloaded. Start by pressing "Reset Simulation". This will setup the agents to run a single simulation. Press "Run Simulation" to run the model. When the simulation is complete, press "Reset Simulation" to revert. Press "Reset Settings" to set settings to default values.

## Humans vs Zombies Quick Rules
Humans vs Zombies is a campus-wide game of tag. Players act as either a Human or a Zombie as they try to survive the Zombie Apocalypse or grow the size of the Horde. Zombies attempt to tag Humans to turn them into Zombies, while Humans defend themselves with stunning implements, including sock balls and Nerf blasters.

Zombies play by attempting to "tag" humans. When a Human is tagged by a Zombie, they die and are resurrected as a Zombie.

Humans play by defending themselves from Zombies by "stunning" them. A human either throws a sock or launches a dart from a blaster at a Zombie. If the zombie is hit by the projectile, they are "stunned" and wait a period of time before resurrecting. 

## Turtles

There are six breeds of turtles in the model: `human`, `zombie`, `projectile`, and a "dead" version for each of the previous breed.

# MODEL PROCEDURES

The model starts by initializing the setup. All the turtles are created and placed. The model the takes turns each tick executing zombie procedures, human procedures, and projectile procedures, in order. The simulation ends when when "Run Simulation" is turned off, there are no more humans, or there are no more zombies.

To best visualize the discrete, ordered nature of the simulation, set "view updates" on the top ribbon to "continuous" and set "speed" to "slower", around 25%. This will show that the zombies move, then the humans, then the projectiles.

## Initialization

The model starts the simulation by creating and placing the humans and zombies. The humans and zombies are placed according to *scenario*. There are two scenarios currently implemented: `charge` and `random`.

#### Scenario: `charge`

Humans and zombies are set up on in two separate clumps according to a normal distribution. The zombies are set up around the point `(0, max-xcor / 2)` while the humans are set up around the point `(0, 0)`. The standard deviation of the distribution in the x direction is given as `zombie/human-charge-spread` while the y direction is given as `zombie/human-charge-spread / 4`. This difference in standard deviations creates the "gun-line" spread normally experienced in charges.

#### Scenario: `random`

Humans and zombies are set up at completely random x and y coordinates. This could be used to simulate a chaotic encounter without structure. 

## Human

During each iteration, humans follow the following procedure:

1. Move according to procedure dictated by `human-move-style`
2. Attempt to launch a projectile according to procedure dictated by `human-launch-style`

### Human Movement

#### Human Move Style

Humans move according to procedure defined by `human-move-style`. There are three move styles currently implemented: `nearest-zombie`, `zone-evasion`, and `hit-and-run`.

If a human runs out of ammo or is jammed, they update their `move-style` to the move style defined by `human-jammed-move-style`.

#### Human Move Style: `nearest-zombie`

The human moves directly away from the nearest zombie. 

#### Human Move Style: `zone-evasion`

The human identifies all zombies within a radius defined by `human-zone-evasion-radius` and moves directly away from the center of mass of the zombies.

#### Human Move Style: `anti-gravity`

The human identifies the gravitation "push" of each zombie according to the inverse square law

#### Human Move Style: `hit-and-run`

The human moves to keep the nearest zombie at a distance equivalent to `launch-range`. The human moves backward or forwards until the nearest zombie is exactly on the launch range.

### Human Launching

To launch a projectile, the human must meet the following criteria:

1. The human is not "cooling down"
2. The human still has projectiles to launch

If a human meets both of these criteria, it will attempt to launch a projectile according to procedure defined by `human-launch-style`. There is one launch style currently implemented: `nearest-zombie-in-range`.

#### Cooldown

Every time a human launches a projectile, it's `cooldown-timer` will reset to `projectile-cooldown`. This represents the amount of time that must pass before the human can take another shot. Every time a human attempts to launch a projectile, even if it fails, the cooldown timer is reduced by the time step. A human is considered "cooled down" when `cooldown-timer <= 0`.

#### Jams

Every time a human attempts to launch a projectile, there is a random chance that they "jam". This represents the random chance that blaster misfires during an engagement. This is not usually a case for sock users, though it could model them dropping all their socks on accident.

Each human is assigned a `jam-rate` according to their projectile type. The jam is modeled by comparing `jam-rate` to a randomly generated number between 0 and 1. If the number is less than the `jam-rate`, `jammed` is set to `true` and `projectiles-remaining` is set to `0`.

A `jam-rate` of 5% corresponds to a jam on average every 12.5 shots while a `jam-rate` of 1% corresponds to a jam on average every 68.0 shots. The equation for average number of shots before jam for a given jam rate is `shots = ( ln(0.5) / ln(1 - jam-rate) ) - 1`. This equation is the inverse of the geometric cumulative distribution function.

When a jam occurs, the human's movement style is reset to the procedure defined by `human-jammed-move-style`.

#### Human Launch Style: `nearest-zombie`

The human will identify the closest zombie that is within `launch-range`. If there exists a zombie within this range, the human will launch a projectile at its current location. If not, the human will not launch a projectile. This procedure uses `launch-range` instead of `projectile-range` to allow for finer tuning of shot doctrine.

#### Human Launch Style: `shot-leading`

The human will identify the closest zombie. The human will identify the `impact-time`, location (`xt` and `yt`), and direction (`theta`) of hitting the closest zombie if they do not change their direction. If the distance is within `launch-range`, the human will alunch a projectile at the impact location. If not, the human will not launch a projectile.

## Zombie

During each iteration, zombies follow the following procedure:

1. Move according to procedure dictated by `zombie-move-style`
2. Attempt to tag target human

### Zombie Targets

At the moment, all zombie move styles use a mechanic for identifying its target using a `zombie-target` link. A zombie target link is a directional link between the zombie and a human that it is currently targeting. Currently, zombie target links are created in the movement procedures according to `zombie-move-style`.

### Zombie Movement

Zombies move according to procedure defined by `zombie-move-style`. There are two move styles currently implemented: `nearest-human` and `targeting`.

#### Zombie Move Style: `nearest-human`

The zombie will identify the closest human. The closes human will be set as the zombie's only `zombie-target` link. The zombie will move directly towards the closest human.

#### Zombie Move Style: `horde-targeting`

A single human will be identified as the horde target according to procedure defined by `horde-target-style`. All zombies will create a `zombie-target` link with this single human. When this human is tagged, zombies will revert to `nearest-human` move style. There are three targeting styles currently implemented: `random`, `CG`, and `nearest-human`.

* `random`: The horde target will be chosen at random from all available humans.

* `CG`: The human closest to the "center of gravity" of the horde will be chosen as the horde target.

* `nearest-human`: The human closest to any given zombie will be chosen as the horde target.

### Zombie Tagging

The zombie will attempt to tag its currently targeted human. If the targeted human is within range dictated by `zombie-tag-range`, the human is marked as dead and replaced with a `dead-human`.

## Projectiles

During each iteration, projectiles follow the following procedure:

The projectile starts by identifying all zombies that satisfy either of the following criteria:

   * Zombie is within `zombie-hitbox-radius` of projectiles starting point.
   * Zombie is within a cone of radius `min of (projectile-speed) and (projectile-range - traveled)` and withing `zombie-hitbox-radius` of the line of travel of the projectile.

The first criteria ensures that all zombies that might slip past the projectile due to the discrete event nature of the simulation are considered. The second criteria ensure that all zombies along the line of path of the projectile are considered. A cone combined with distance from line are used as rotated rectangular area selection of zombies is not included in NetLogo. The radius of the cone is selected as the minimum of `projectile-speed` and `projectile-range - traveled` to ensure that the implement does not stun a zombie outside of it's range.

If there is a zombie that satisfies these criteria, the projectile finds the closest one, moves to it, and stuns it. The zombie is marked as dead and is replaced with a `dead-zombie`.

If there is not a zombie that satisfies these criteria, the projectile travels forwards the minimum of `projectile-speed` and `projectile-range - traveled`. The distance traveled is updated. If `projectile-range = traveled`, the projectile dies and is replaced with a `dead-projectile`.


# MODEL SETTINGS

The function of all the settings on the interface tab are described below. Default values are shown in (parentheses). Units are shown in [brackets].

## Simulation Settings
* **ticks-per-second (30)**: Number of discrete time-steps that occur per second (Hz).
* **real-time (true)**: Whether the model is forced to run at real time. Recommended to set speed to normal for optimal performance. Set high ticks-per-second for buttery smooth visualization.
* **show-number-projectiles (true)**: Show number of remaining projectiles next to human sprite. Shows *X* if human experiences a jam.
* **show-zombie-targets (true)**: Shows links between zombies and their target humans.

## Scenario Settings
* **scenario (`charge`)**: Select setup of humans and zombies. Options: `charge`, `random`.
* **zombie/human-charge-spread (15 / 25)**: Measure of how spread out the humans and zombies are in `charge` scenario. Directly related to standard deviation of a normal function.
 
## Faction Count Settings
* **num-sock-humans (5)**: Number of sock humans
* **num-blaster-humans (5)**: Number of blaster humans
* **num-zombies (50)**: Number of zombies

## Faction Ability Settings
* **human-speed (20) [ft/s]**: Movement speed of a human
* **zombie-speed (20) [ft/s]**: Movement speed of a zombie
* **zombie-tag-range (2) [ft]**: Distance a zombie can tag a human from
* **zombie-hitbox-radius (2) [ft]**: Distance a stunning implement can stun a zombie from

## Sock/Blaster Settings
* **starting-socks/darts (10 / 30)**: Number of socks/darts a human starts with
* **sock/dart-speed (35 / 80) [ft/s]**: Movement speed of socks/darts
* **sock/dart-range (35 / 50) [ft]**: Total range of socks/darts
* **sock/dart-cooldown (1.5 / 1) [s]**: How long a human must wait to fire sock/dart
* **sock/dart-inaccuracy (5 / 25) [degrees]**: Range of inaccuracy for sock/dart
* **sock/dart-jam-rate (0 / 1) [%]**: How often firing a sock/dart results in a jam

## Human AI Settings

For full description of procedures, see HUMAN section.

* **human-move-style (`hit-and-run`)**: Select movement style of humans. Options: `nearest-zombie`, `zone-evasion`, `anti-gravity`, `hit-and-run`.
* **human-jammed-move-style (`zone-evasion`)**: Select movement style of a human when out of ammo. Options: `nearest-zombie`, `zone-evasion`, `anti-gravity` `hit-and-run`.
* **human-zone-evasion-radius (20) [ft]**: Radius of circle detailing which zombies the human will evade in `zone-evasion` mode. 
* **human-launch-style (`shot-leading`)**: Select launch style of humans. Options: `nearest-zombie-in-range`, `shot-leading`.
* **sock/dart-launch-range [20 / 20]**: Range where a human will launch projectile. Defaulted to range of projectile.

## Zombie AI Settings

For full description of procedures, see ZOMBIE section.

* **zombie-move-style (`hit-and-run`)**: Select move style of zombies.  Options: `nearest-human`, `targeting`.
* **horde-target-style (`CG`)**: Select horde target style. Options: `random`, `CG`, `nearest-human`.

# RUNNING EXPERIMENTS

Experiements are run using NetLogo's built in BehaviorSpace. For a further detail of how to use BehaviorSpace, check out the [BehaviorSpace Documentation](http://ccl.northwestern.edu/netlogo/docs/behaviorspace.html).

# CREDITS AND REFERENCES

Website: https://scottnealon.github.io/HumansVsZombies/
GitHub Repository: https://github.com/ScottNealon/HumansVsZombies/

Special thanks to Scott Nealon, Josh Netter, Sriram Ganesan, and Adithya Nott