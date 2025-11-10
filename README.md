# DrawDogOnline

Recreating Chicory: A Colorful Tale drawing in Godot and adding online functionality

## Playing

Download from [releases](https://github.com/JdavisBro/DrawDogOnline/releases)

Start the execuatable, put in your IP!

### Features

- Undo and Redo: `ctrl + z`, `ctrl + shift + z`
- Fill Bucket! `1`
  - The fill bucket in Chicory will fill through corners, in DrawDogOnline there is an option to disable that in settings
- Quick Color Swapping! Hold `tab` and move your mouse to select
- Palette setting! Press `esc` and click Set palette
- Ruler! Hold `r` and it'll measure distance between that point and where you move your mouse
- Chat: press `t` to chat

## Hosting a Server

Download from [releases](https://github.com/JdavisBro/DrawDogOnline/releases)

Run the executable with arguments as follows (example uses linux executable)

`./DrawDog.x86_64 server-start default`

You can replace default with a port number.

## Discord Authentication

> Note: Using Discord authentication requires SSL / using the wss:// protocol

add `--authtype discord` to your launch arguments

make an application at https://discord.com/developers/applications

Go to OAuth2 -> General. Copy client id and put it in a file named `client_id` in below dir. Do the same with the secret in `client_secret`

- Windows: `%appdata%\Godot\app_userdata\Draw Dog Online\`
- Linux: `~/.local/share/Godot/app_userdata/Draw Dog Online/`

Add `http://127.0.0.1:38493/` to the redirect url

Also add `WebVersionHost/auth.html` (e.g. `https://jdavisbro.github.io/DrawDogOnline/auth.html`) to support web version

> if you're hosting this web version make sure to include the auth.html in the root of the respository

## Contributing/Exporting

Requires

- [Godot 4.5.1](https://godotengine.org/download/archive/4.5.1-stable/)
- [UndertaleModTool](https://github.com/krzys-h/UndertaleModTool/)

First (before opening the repo in Godot) create an Export_Sprites and Exported_Sounds with UndertaleModTool and move it to this repo dir.

Add a file named `.gdignore` to Export_Sprites/

In the base dir run `py -m pip install -r requirements.txt` and `py move_assets.py`

Now you can open it (and export if you want) in Godot :D

To import the brush sounds properly, find sfx/erase/loop/mono.wav and sfx/paint/medium_loop.wav in the assets folder. Select them and, from the import tab (top left), select Loop Mode > Forward and Reimport.

## Credits

Domigorgon Plus font by [Legendknight 3000](https://www.youtube.com/@Legendknight3000).

Game assets distributed with releases are from Chicory: A Colorful Tale

Game based on Chicory: A Colorful Tale

You should play Chicory: A Colorful Tale

Chicory: A Colorful Tale™ © 2021 Greg Lobanov. All rights reserved. Finji® and regal weasel and crown logo are trademarks of Finji, LLC.
