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

    const deleteMessage = (messageId) => {
      this.pushEvent("delete_message", { "message-id": messageId });
    };

    const data = JSON.parse(this.el.dataset.settings);

    const props = {
      messages: data.messages,
      slowModeSec: data.slowModeSec,
      maxBodyLength: data.maxBodyLength,
      maxAuthorLength: data.maxAuthorLength,
      role: data.role,
      sendMessage,
      messageSentListener: (listener) => {
        this.handleEvent("new-message", listener);
      },
      messageFlaggedListener: (listener) => {
        this.handleEvent("flagged-message", listener);
      },
      messageUnflaggedListener: (listener) => {
        this.handleEvent("unflagged-message", listener);
      },
      messageDeletedListener: (listener) => {
        this.handleEvent("deleted-message", listener);
      },
      flagMessage,
      deleteMessage,
    };

    render(h(Chat, props), this.el);
  },
};
