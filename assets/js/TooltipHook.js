/**
 * @type {import("phoenix_live_view").ViewHookInterface}
 */
export default {
  mounted() {
    /**
     * @type {HTMLDivElement}
     */
    const tooltipContent = this.el.querySelector(".tooltip-content");

    this.el.addEventListener("pointerenter", () => {
      const { width: elWidth, x, y } = this.el.getBoundingClientRect();

      tooltipContent.style.display = "block";
      tooltipContent.style.opacity = "75%";

      tooltipContent.style.left =
        x -
        tooltipContent.getBoundingClientRect().width / 2 +
        elWidth / 2 +
        "px";
      tooltipContent.style.top =
        y - tooltipContent.getBoundingClientRect().height - 2 + "px";
    });

    this.el.addEventListener("pointerleave", (ev) => {
      tooltipContent.style.display = "none";
    });
  },
};
