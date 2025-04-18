/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    this.el.addEventListener("keydown", (e) => {
      if (e.key !== "Enter" || e.shiftKey) {
        return;
      }

      this.pushEvent("submit-form", { body: e.target.value });
      if (this.el.dataset.slowMode === "false") {
        e.target.value = "";
      }

      e.preventDefault();
    });
  },
};
