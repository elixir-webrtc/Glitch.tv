# Glitch.tv

**Glitch.tv** is a streaming platform written in the Elixir programming language using [LiveExWebRTC](https://github.com/elixir-webrtc/live_ex_webrtc) Components.

[LiveExWebRTC](https://github.com/elixir-webrtc/live_ex_webrtc) is library of Phoenix Live Components allowing for simple use of [Elixir WebRTC](https://github.com/elixir-webrtc/ex_webrtc).

## Features 
- streaming camera and audio directly from browser
- live chat for all the viewers with moderation features
- automatic stream recording and integrated recordings 

## Installation and running

1. Clone the repository
   ```
   git clone https://github.com/elixir-webrtc/elixir-conf-platform.git
   ```
2. Install dependencies
   ```
   cd elixir-conf-platform
   mix deps.get
   ```
3. Setup the database
   ```
   mix ecto.create
   ```
4. Run the server
   ```
   mix phx.server
   ```
6. Enter [localhost:4000](http://localhost:4000). Streamer panel is available at [localhost:4000/streamer](http://localhost:4000/streamer) *(in dev mode username is "username", password is "password")*

### Variables
Environonmental variables used by _Glitch.tv_
- `GLITCH_STREAMER_USERNAME` - username for streamer panel in prod mode,
- `GLITCH_STREAMER_PASSWORD` - password for streamer panel in prod mode,
- `GLITCH_ENABLE_RECORDINGS` - flag for enablig recordings, defaults to false
- `GLITCH_SLOW_MODE_DELAY_S` - chat slow mode's delay in seconds, defaults to 1

---

## Credits

Elixir WebRTC is created by [Software Mansion](https://swmansion.com/).

Since 2012 Software Mansion is a software agency with experience in building web and mobile apps as well as complex multimedia solutions. We are Core React Native Contributors and experts in live streaming and broadcasting technologies. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects).

[![swm](https://logo.swmansion.com/logo?color=white&variant=desktop&width=150 'Software Mansion')](https://swmansion.com)
