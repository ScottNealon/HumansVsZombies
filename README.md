# Humans Vs Zombies: An Agent-based Model
This GitHub contains the files for an agent-based model of the popular campus game Humans vs Zombies. The model is implemented in popular agent-based modeling program NetLogo.

[Quick access link](http://netlogoweb.org/web?https://raw.githubusercontent.com/ScottNealon/HumansVsZombies/master/main.nlogo)

## Brief Overview of Humans vs Zombies

Humans vs Zombies is a campus-wide game of tag. Players act as either a Human or a Zombie as they try to survive the Zombie Apocalypse or grow the size of the Horde. Zombies attempt to tag Humans to turn them into Zombies, while Humans defend themselves with stunning implements, including sock balls and nerf blasters.

For more information on rules, check out the [official Humans vs Zombies webiste](https://humansvszombies.org/) or the [Georgia Tech Humans vs Zombies website](https://hvz.gatech.edu/rules/).

## Running the Model
The model can be run in one of two formats: NetLogo Web and NetLogo Desktop.

The NetLogo Web format is run from [NetLogoWeb.org](https://netlogoweb.org). By directing the website towards this repository, the most recent version of the model can be run. You can access this by following the following link: [Humans vs Zombies NetLogo Web](http://netlogoweb.org/web?https://raw.githubusercontent.com/ScottNealon/HumansVsZombies/master/main.nlogo)

The NetLogo Desktop format is run from a desktop application. To download the application, go to [the NetLogo application download page](https://ccl.northwestern.edu/netlogo/download.shtml). Additionally, download [main.nlogo](https://github.com/ScottNealon/HumansVsZombies/blob/master/main.nlogo) from this repository. The model can be run and edited by opening main.nlogo in the NetLogo application.

## Model Tutorial

The model starts out unloaded. Start by pressing "Reset Simulation". This will setup the agents to run a single simulation. Press "Run Simulation" to run the model. When the simulation is complete, press "Reset Simulation" to revert. Press "Reset Settings" to set settings to default values.

A more thorough tutorial for the model can be found under the INFO tab in the model.

## Building the Source Code

To generate the NetLogo file, use the build.py script. It is intended to work for both Python 2.7 and Python 3.5. The dev folder serves as the most up-to-date set of the content being used in the project.

Below are some common commands to use:
```console
# Provides details on how to use the script and the flags/arguments the script accepts
python build.py -h

# Creates a NetLogo file called hvz-vX.nlogo (via the dev/ subdirectory as default)
python build.py hvz-vX.nlogo

# Takes an existing NetLogo file called hvz-vX.nlogo and creates a directory (at deconstructed/ as default) with the NetLogo content split up accordingly.
python build.py hvz-vX.nlogo -d
```