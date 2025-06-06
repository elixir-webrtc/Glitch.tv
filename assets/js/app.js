// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html";
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import topbar from "../vendor/topbar";
import { createPublisherHook, createPlayerHook } from "live_ex_webrtc";
import ShareButtonHook from "./ShareButtonHook";
import DarkModeToggleHook from "./DarkModeToggleHook";
import TooltipHook from "./TooltipHook";
import ChatHook from "./ChatHook";

let Hooks = {};

Hooks.ShareButton = ShareButtonHook;
Hooks.DarkModeToggleHook = DarkModeToggleHook;
Hooks.TooltipHook = TooltipHook;
Hooks.ChatHook = ChatHook;

config = document.getElementById("config").dataset
const defaultIceServers = [{ urls: "stun:stun.l.google.com:19302" }]
const iceServers = config.iceServers != undefined ? defaultIceServers.concat(JSON.parse(config.iceServers)) : defaultIceServers;
Hooks.Publisher = createPublisherHook(iceServers);
Hooks.Player = createPlayerHook(iceServers);

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {
    _csrf_token: csrfToken,
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  },
  hooks: Hooks,
});

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" });
window.addEventListener("phx:page-loading-start", (_info) => topbar.show(300));
window.addEventListener("phx:page-loading-stop", (_info) => topbar.hide());

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

if (
  localStorage.getItem("color-theme") === "dark" ||
  (!("color-theme" in localStorage) &&
    window.matchMedia("(prefers-color-scheme: dark)").matches)
) {
  document.documentElement.classList.add("dark");
} else {
  document.documentElement.classList.remove("dark");
}

