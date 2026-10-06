# Sunny Side Café

A calm, little-kid-friendly restaurant game made with **LÖVE (Love2D)**. The game opens fullscreen. All visuals are drawn from shapes in `main.lua`; there are no external art assets, purchases, penalties, or service deadlines.

## Play

Run this folder with LÖVE 11.4 or newer:

```sh
love .
```

- **Move:** use **WASD / arrow keys**. The mouse never moves the worker.
- **Select a friend:** click their character. Walk close and press **E** or **Space** to take their order.
- **Choose the order:** click its food picture at the bottom, or press its number (**0** is French fries).
- **Prepare it:** walk through the gap in the counter to the indicated **Drinks**, **Grill**, **Oven**, or **Prep** station. Press **E** or **Space** and watch the station countdown.
- **Serve:** when cooking finishes, walk close to the selected friend and press **E** or **Space**.
- **Fullscreen:** press **F11** to toggle fullscreen; **Esc** exits.

Friends arrive at an easy pace. The counter and kitchen islands block the worker, so use the central gap to walk between dining and kitchen areas. Cooking countdowns show how long each item takes, but they never expire and no one is penalized for taking their time. A wrong food choice gives a gentle hint. Serving friends adds happy-friend stars.

The menu includes soda, hot dog, hamburger, pie, lollipop, bread, salad, candy, pizza, and French fries.# food_game
