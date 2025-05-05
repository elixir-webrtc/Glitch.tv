/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    const emojiPickers = this.el.querySelectorAll("emoji-picker");
    const messageBodyTextBox = this.el.querySelector("#message_body");
    const messageBoxList = this.el.querySelector("#message_box");

    messageBoxList.scrollTo(0, messageBoxList.scrollHeight);

    this.handleEvent("new-message", () => {
      if (
        messageBoxList.scrollTop + messageBoxList.clientHeight ===
          messageBoxList.scrollHeight -
            messageBoxList.lastElementChild.clientHeight ||
        messageBoxList.clientHeight >
          messageBoxList.scrollHeight -
            messageBoxList.lastElementChild.clientHeight
      ) {
        messageBoxList.scrollTo(0, messageBoxList.scrollHeight);
      }
    });

    for (const emojiPicker of emojiPickers) {
      emojiPicker.addEventListener("emoji-click", (event) => {
        this.pushEvent("append_emoji", { emoji: event.detail.unicode });
      });
    }

    messageBodyTextBox.addEventListener("keydown", (e) => {
      if (e.key !== "Enter" || e.shiftKey) {
        return;
      }

      this.pushEvent("submit-form", { body: e.target.value });
      if (this.el.dataset.slowMode === "false") {
        e.target.value = "";
      }

      e.preventDefault();
    });

    messageBoxList.addEventListener("scroll", () => {
      const tooltips = this.el.querySelectorAll(".tooltip-content");

      for (const tooltip of tooltips) {
        tooltip.style.display = "none";
      }
    });
  },
};
