# Glitch.tv

**Glitch.tv** is a streaming platform written in the Elixir programming language using [LiveExWebRTC](https://github.com/elixir-webrtc/live_ex_webrtc) Components.

[LiveExWebRTC](https://github.com/elixir-webrtc/live_ex_webrtc) is a library of Phoenix Live Components allowing for simple use of [Elixir WebRTC](https://github.com/elixir-webrtc/ex_webrtc).

## Features 
- Streaming camera and audio directly from browser
- Live chat for all the viewers with moderation features
- Automatic stream recording and integrated recordings 
- Supports markdown in stream title, description and chat

## Installation and running

1. Clone the repository
   ```sh
   git clone https://github.com/elixir-webrtc/elixir-conf-platform.git
   ```
2. Install dependencies
   ```sh
   cd elixir-conf-platform
   mix deps.get
   ```
### Development mode
3. Setup the database
   ```sh
   mix ecto.create
   ```
4. Run the server
   ```sh
   mix phx.server
   ```
6. Streamer panel is available at [localhost:4000/streamer](http://localhost:4000/streamer) _(in dev mode username is "username", password is "password")_

### Production Mode
3. Setup the database
   ```sh
   MIX_ENV=prod mix ecto.create
   ```
4. Run the server
   ```sh
   MIX_ENV=prod SECRET_KEY_BASE=$(mix phx.gen.secret) PHX_HOST=<hostname> PORT=<port-nr> STREAMER_USERNAME=<username> STREAMER_PASSWORD=<password> GLITCH_SLOW_MODE_DELAY_S=<delay-sec> DATABASE_PATH=mix phx.server
   ```
6. Streamer panel is available at <ins>\<hostname\>/streamer</ins> _(in dev mode username is "username", password is "password")_

### Environment variables
In development mode the environment variables are specified in `config/dev.exs`, feel free to adjust them as you'd like. If you're preparing a production release of _Glitch.tv_ however, make sure to specify the following environmental variables while running the application:
- `GLITCH_STREAMER_USERNAME` - username for streamer panel in prod mode,
- `GLITCH_STREAMER_PASSWORD` - password for streamer panel in prod mode,
- `GLITCH_ENABLE_RECORDINGS` - flag for enabling recordings, defaults to false
- `GLITCH_SLOW_MODE_DELAY_S` - chat slow mode's delay in seconds, defaults to 1

---

## Credits

Elixir WebRTC is created by [Software Mansion](https://swmansion.com/).

Since 2012 Software Mansion is a software agency with experience in building web and mobile apps as well as complex multimedia solutions. We are Core React Native Contributors and experts in live streaming and broadcasting technologies. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects).

[![swm](https://logo.swmansion.com/logo?color=white&variant=desktop&width=150 'Software Mansion')](https://swmansion.com)
