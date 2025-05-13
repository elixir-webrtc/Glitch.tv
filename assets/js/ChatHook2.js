import { render, h } from "preact";
import { Chat } from "./chat/chat";

/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    const sendMessage = (message, callback) => {
      this.pushEvent(
        "submit-form",
        {
          author: message.author,
          body: message.body,
        },
        callback
      );
    };

    const flagMessage = (messageId) => {
      this.pushEvent("flag-message", { "message-id": messageId });
    };

    const props = {
      messages: JSON.parse(this.el.dataset.messages),
      sendMessage,
      messageSentListener: (listener) => {
        this.handleEvent("new-message", listener);
      },
      messageFlaggedListener: (listener) => {
        this.handleEvent("flagged-message", listener);
      },
      flagMessage,
    };

    render(h(Chat, props), this.el);
  },
};
