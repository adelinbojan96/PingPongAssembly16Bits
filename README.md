# PingPongAssembly16Bits
A game designed for one or two players, resembling the old ping pong application. It utilized software interrupts to generate pixels and was compiled using MASM.

# Description
The game works by detecting a collision. Whenever the ball touches a paddle, its velocity changes the direction. When a left or a right wall is hit,
the ball changes the orientation. The ball is a rectangle made of pixels, as well as the paddles. 
The user has 2 ways to play: either alone, or with another player. 'A' and 'D' are used by the first player, '4' and '6' are used by the second player.
The first one to score 10 points wins.
At the end, a window with the winner will be displayed. 'R' is for restarting the game and 'M' to return to the main menu. 

![New Project](https://github.com/user-attachments/assets/5f7fbf3c-7d98-4602-b6a7-34d9a73508d5)
