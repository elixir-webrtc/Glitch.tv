import classNames from "classnames";
import { h, JSX } from "preact";
import { useEffect, useRef } from "preact/hooks";

type Props = {
  tooltip: string;
  show?: boolean;
} & JSX.ElementChildrenAttribute;

export function Tooltip({ children, tooltip, show = false }: Props) {
  const wrapperRef = useRef<HTMLDivElement>(null);
  const tooltipRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const wrapperPointerEnterCallback = () => {
      const {
        width: elWidth,
        x,
        y,
      } = wrapperRef.current!.getBoundingClientRect();

      tooltipRef.current!.style.left =
        x -
        tooltipRef.current!.getBoundingClientRect().width / 2 +
        elWidth / 2 +
        "px";
      tooltipRef.current!.style.top =
        y - tooltipRef.current!.getBoundingClientRect().height - 2 + "px";
    };

    wrapperRef.current!.addEventListener(
      "pointerenter",
      wrapperPointerEnterCallback
    );

    return () =>
      wrapperRef.current?.removeEventListener(
        "pointerenter",
        wrapperPointerEnterCallback
      );
  }, []);

  return (
    <div class="cursor-default">
      <div ref={wrapperRef}>{children}</div>
      <div
        ref={tooltipRef}
        class={classNames(
          "fixed w-max px-2 py-1 rounded-xl bg-stone-900 opacity-75",
          {
            visible: show,
            invisible: !show,
          }
        )}
      >
        <p class="text-xs text-white">{tooltip}</p>
      </div>
    </div>
  );
}
