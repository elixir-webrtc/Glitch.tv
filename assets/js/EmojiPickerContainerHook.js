/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    const emojiPickers = document.querySelectorAll("emoji-picker");

    for (const emojiPicker of emojiPickers) {
      emojiPicker.addEventListener("emoji-click", (event) => {
        this.pushEvent("append_emoji", { emoji: event.detail.unicode });
      });
    }

    document.addEventListener("pointerdown", (e) => {
      let shouldHide =
        !emojiPickers[0].contains(e.target) &&
        !emojiPickers[1].contains(e.target);

      const isParentHidden =
        emojiPickers[0].parentElement.classList.contains("hidden");

      if (shouldHide && !isParentHidden) {
        this.pushEvent("hide-emoji-overlay", {});
      }
    });
  },
};
