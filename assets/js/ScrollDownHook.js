/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    this.el.scrollTo(0, this.el.scrollHeight);

    this.handleEvent("new-message", () => {
      if (
        this.el.scrollTop + this.el.clientHeight ===
          this.el.scrollHeight - this.el.lastElementChild.clientHeight ||
        this.el.scrollTop + this.el.clientHeight < this.el.scrollHeight
      ) {
        this.el.scrollTo(0, this.el.scrollHeight);
      }
    });
  },
};
