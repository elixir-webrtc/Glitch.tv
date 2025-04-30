/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */

import { render, h } from "preact";
import { Chat } from "./chat/chat";

export default {
  mounted() {
    render(h(Chat, null), this.el);
  },
};
