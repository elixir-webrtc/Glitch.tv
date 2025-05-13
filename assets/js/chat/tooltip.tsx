import classNames from "classnames";
import { h, JSX } from "preact";

type Props = {
  tooltip: string;
  show?: boolean;
} & JSX.ElementChildrenAttribute;

export function Tooltip({ children, tooltip, show = false }: Props) {
  return (
    <div class="relative cursor-default">
      {children}
      <div
        class={classNames(
          "absolute w-max px-2 py-1 rounded-xl bg-stone-900 left-1/2 top-0 -translate-x-1/2 -translate-y-[calc(100%+2px)] opacity-75",
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
