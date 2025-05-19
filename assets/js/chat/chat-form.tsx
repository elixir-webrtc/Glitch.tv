import classNames from "classnames";
import { JSX, h } from "preact";
import { useEffect, useRef, useState } from "preact/hooks";
import { Message, SendMessageResultPayload } from "./types";

type Props = {
  sendMessage: (
    message: Omit<Message, "id">,
    callback: (reply: SendMessageResultPayload) => void
  ) => void;
};

export default function ChatForm({ sendMessage }: Props) {
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);
  const formRef = useRef<HTMLFormElement>(null);
  const [joined, setIsJoined] = useState(false);
  const [author, setAuthor] = useState("");
  const [textAreaMessage, setTextAreaMessage] = useState("");
  const [isSlowModeHighlighted, setIsSlowModeHighlighted] = useState(false);
  const delayRef = useRef(0);
  const emojiPickerRef = useRef<HTMLFormElement>(null);

  useEffect(() => {
    emojiPickerRef.current?.addEventListener("emoji-click", (e) => {
      // @ts-ignore
      setTextAreaMessage((prev) => prev + e.detail.unicode);
    });
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
        <p
          class={classNames("text-xs", {
            "text-rose-600": isSlowModeHighlighted,
            "text-neutral-400": !isSlowModeHighlighted,
          })}
        >
          Slow Mode 5s
        </p>
        <div class="flex items-end gap-2">
          <textarea
            name="body"
            class="glitch-input-primary resize-none h-[64px] w-full dark:text-neutral-400"
            placeholder="Your message"
            disabled={!joined}
            onKeyDown={onTextAreaKeydown}
            onInput={onTextAreaInput}
            value={textAreaMessage}
          ></textarea>
          <div class="relative">
            <button
              type="button"
              class="border border-indigo-200 rounded-lg px-2 py-1 disabled:opacity-50 dark:text-neutral-400 dark:border-zinc-800 dark:bg-zinc-800"
              disabled={!joined}
              onClick={() => setShowEmojiPicker((prev) => !prev)}
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
        <input
          type="text"
          name="author"
          class="glitch-input-primary px-4 py-2"
          placeholder="Your nickname"
          onInput={onAuthorInput}
          value={author}
          disabled={joined}
        />
        <input
          type="submit"
          value={author.length === 0 ? "Join" : "Send"}
          class="glitch-button-primary"
          disabled={author.length === 0}
        />
      </div>
    </form>
  );
}
