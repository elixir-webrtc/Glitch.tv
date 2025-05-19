import classNames from "classnames";
import { JSX, h } from "preact";
import { useEffect, useRef, useState } from "preact/hooks";
import { Message, SendMessageResultPayload } from "./types";
import "emoji-picker-element";

type Props = {
  slowModeSec: number;
  maxBodyLength: number;
  maxAuthorLength: number;

  sendMessage: (
    message: Omit<Message, "id">,
    callback: (reply: SendMessageResultPayload) => void
  ) => void;
};

export default function ChatForm({
  sendMessage,
  slowModeSec,
  maxBodyLength,
  maxAuthorLength,
}: Props) {
  const [isSlowModeHighlighted, setIsSlowModeHighlighted] = useState(false);
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const [textAreaMessage, setTextAreaMessage] = useState("");
  const emojiPickerRef = useRef<HTMLFormElement>(null);
  const emojiButtonRef = useRef<HTMLButtonElement>(null);
  const formRef = useRef<HTMLFormElement>(null);
  const [joined, setIsJoined] = useState(false);
  const [author, setAuthor] = useState("");
  const delayRef = useRef(0);

  useEffect(() => {
    emojiPickerRef.current?.addEventListener("emoji-click", (e) => {
      // @ts-ignore
      setTextAreaMessage((prev) => prev + e.detail.unicode);
      setShowEmojiPicker(false);
    });

    const documentClickCallback = (event: PointerEvent) => {
      if (
        emojiPickerRef.current &&
        emojiButtonRef.current &&
        !emojiPickerRef.current.contains(event.target as Element) &&
        !emojiButtonRef.current.contains(event.target as Element)
      ) {
        setShowEmojiPicker((prev) => {
          if (prev) {
            return false;
          }
          return prev;
        });
      }
    };

    document.addEventListener("pointerdown", documentClickCallback);

    return () =>
      document.removeEventListener("pointerdown", documentClickCallback);
  }, []);

  useEffect(() => {
    if (isSlowModeHighlighted) {
      const timeoutId = setTimeout(
        () => setIsSlowModeHighlighted(false),
        delayRef.current
      );

      return () => {
        clearTimeout(timeoutId);
        delayRef.current = 0;
      };
    }
  }, [isSlowModeHighlighted]);

  const onTextAreaKeydown = (
    e: JSX.TargetedKeyboardEvent<HTMLTextAreaElement>
  ) => {
    if (e.key !== "Enter" || e.shiftKey) {
      return;
    }

    e.preventDefault();

    formRef.current?.requestSubmit();
  };

  const onTextAreaInput = (e: JSX.TargetedInputEvent<HTMLTextAreaElement>) => {
    setTextAreaMessage(e.currentTarget.value);
  };

  const onAuthorInput = (e: JSX.TargetedInputEvent<HTMLInputElement>) => {
    setAuthor(e.currentTarget.value);
  };

  const submitForm = (ev: SubmitEvent) => {
    ev.preventDefault();

    if (!joined) {
      setIsJoined(true);
      return;
    }

    const payload = {
      author: author,
      body: textAreaMessage,
      inserted_at: new Date().toISOString(),
      flagged: false,
    };

    sendMessage(payload, (reply) => {
      if (reply.action === "done") {
        setTextAreaMessage("");
        return;
      }

      delayRef.current = reply.delay;

      setIsSlowModeHighlighted(true);
    });
  };

  return (
    <form
      ref={formRef}
      onSubmit={submitForm}
      class="border-t border-indigo-200 p-6 pt-4 dark:border-zinc-800 flex flex-col gap-2"
    >
      <div class="flex flex-col gap-2">
        <div class="flex items-center justify-between">
          <p
            class={classNames("text-xs", {
              "text-rose-600": isSlowModeHighlighted,
              "text-neutral-400 dark:text-neutral-700": !isSlowModeHighlighted,
            })}
          >
            Slow Mode {slowModeSec}s
          </p>
          <div
            class={classNames(
              "text-xs text-neutral-400 dark:text-neutral-700",
              {
                hidden: textAreaMessage.length < maxBodyLength - 50,
                "text-rose-600 dark:text-rose-600":
                  textAreaMessage.length === maxBodyLength,
              }
            )}
          >
            {textAreaMessage.length}/{maxBodyLength}
          </div>
        </div>
        <div class="flex items-end gap-2">
          <textarea
            name="body"
            class="glitch-input-primary resize-none h-[64px] w-full dark:text-neutral-400"
            placeholder="Your message"
            disabled={!joined}
            onKeyDown={onTextAreaKeydown}
            onInput={onTextAreaInput}
            value={textAreaMessage}
            maxLength={maxBodyLength}
          ></textarea>
          <div class="relative">
            <button
              type="button"
              class="border border-indigo-200 rounded-lg px-2 py-1 disabled:opacity-50 dark:text-neutral-400 dark:border-zinc-800 dark:bg-zinc-800"
              disabled={!joined}
              onClick={() => setShowEmojiPicker((prev) => !prev)}
              ref={emojiButtonRef}
            >
              <span class="hero-face-smile"></span>
            </button>
            <div
              class={classNames("absolute bottom-[calc(100%+4px)] right-0", {
                hidden: !showEmojiPicker,
              })}
            >
              {h("emoji-picker", { ref: emojiPickerRef })}
            </div>
          </div>
        </div>
      </div>
      <div class="flex gap-2">
        <div class="flex flex-1 flex-col gap-1 relative">
          <input
            type="text"
            name="author"
            class="glitch-input-primary px-4 py-2"
            placeholder="Your nickname"
            onInput={onAuthorInput}
            value={author}
            disabled={joined}
            maxLength={maxAuthorLength}
          />
          <p
            className={classNames(
              "absolute bottom-[-18px] right-0 text-xs w-full text-neutral-400 dark:text-neutral-700",
              {
                hidden: author.length < maxAuthorLength - 5,
                "text-rose-600": author.length === maxAuthorLength,
              }
            )}
          >
            {author.length}/{maxAuthorLength}
          </p>
        </div>
        <input
          type="submit"
          value={!joined ? "Join" : "Send"}
          class="glitch-button-primary"
          disabled={author.length === 0}
        />
      </div>
    </form>
  );
}
