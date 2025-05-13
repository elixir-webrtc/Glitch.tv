import { h, JSX } from "preact";
import { useEffect, useRef, useState } from "preact/hooks";
import classNames from "classnames";
import { Tooltip } from "./tooltip";
import "emoji-picker-element";

type ReplyPayload =
  | {
      action: "done";
      message: Message;
    }
  | {
      action: "delayed";
      delay: number;
    };

type Message = {
  id: number;
  author: string;
  body: string;
  inserted_at: string;
  flagged: boolean;
};

type Props = {
  messages: Message[];
  sendMessage: (
    message: Omit<Message, "id">,
    callback: (reply: ReplyPayload) => void
  ) => void;
  flagMessage: (messageId: number) => void;
  messageSentListener: (listener: (message: Message) => void) => void;
  messageFlaggedListener: (listener: (payload: { id: number }) => void) => void;
};

export function Chat({
  messages: initialMessages,
  sendMessage,
  messageSentListener,
  messageFlaggedListener,
  flagMessage,
}: Props) {
  const [joined, setIsJoined] = useState(false);
  const [author, setAuthor] = useState("");
  const [textAreaMessage, setTextAreaMessage] = useState("");
  const listRef = useRef<HTMLUListElement>(null);
  const formRef = useRef<HTMLFormElement>(null);
  const emojiPickerRef = useRef<HTMLFormElement>(null);
  const [messages, setMessages] = useState(initialMessages);
  const [isSlowModeHighlighted, setIsSlowModeHighlighted] = useState(false);
  const delayRef = useRef(0);
  const [dateTooltipId, setDateTooltipId] = useState<number | undefined>();
  const [reportTooltipId, setReportTooltipId] = useState<number | undefined>();
  const [showEmojiPicker, setShowEmojiPicker] = useState(false);

  useEffect(() => {
    emojiPickerRef.current?.addEventListener("emoji-click", (e) => {
      // @ts-ignore
      setTextAreaMessage((prev) => prev + e.detail.unicode);
    });

    messageSentListener((message) => {
      setMessages((prev) => prev.concat([message]));
    });

    messageFlaggedListener(({ id: messageId }) => {
      setMessages((prev) =>
        prev.map((message) => {
          if (message.id !== messageId) {
            return message;
          }

          return { ...message, flagged: true };
        })
      );
    });
  }, []);

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

  useEffect(() => {
    if (isSlowModeHighlighted) {
      const timeoutId = setTimeout(
        () => setIsSlowModeHighlighted(false),
        delayRef.current
      );

      return () => clearTimeout(timeoutId);
    }
  }, [isSlowModeHighlighted]);

  const scrollToBottom = () => {
    if (listRef) {
      listRef.current?.scrollTo(0, listRef.current.scrollHeight);
    }
  };

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

  const onListScrolled = (e: JSX.TargetedMouseEvent<HTMLUListElement>) => {
    setDateTooltipId(undefined);
    setReportTooltipId(undefined);
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  return (
    <div class="border border-indigo-200 rounded-lg h-full flex flex-col">
      <div class="py-4 px-8 border-b border-indigo-200 text-center dark:border-zinc-800 dark:text-neutral-400 hidden lg:block">
        Chat
      </div>
      <div class="p-2 text-center text-xs border-b-[1px] border-indigo-200 dark:border-zinc-800 dark:text-neutral-400">
        This is not an official ElixirConf EU chat, so if you have any questions
        for the speakers, please ask them under the SwapCard stream.
      </div>
      <ul
        class="overflow-y-auto flex-grow flex flex-col"
        ref={listRef}
        onScroll={onListScrolled}
      >
        {messages.map((message) => (
          <li
            class={classNames(
              "flex flex-col gap-1 px-6 py-4 relative message_box__element hover:bg-stone-100 dark:hover:bg-stone-800",
              {
                "bg-red-100 hover:bg-red-200 dark:bg-red-900 dark:hover:bg-red-800":
                  message.flagged,
                "hover:bg-stone-100 dark:hover:bg-stone-800": !message.flagged,
              }
            )}
          >
            <div class="flex gap-4 justify-between items-center">
              <div class="flex gap-4 items-center">
                <p class="text-indigo-800 text-sm text-medium dark:text-indigo-400">
                  {message.author}
                </p>
                <div class="group relative">
                  <Tooltip
                    tooltip={formatDate(new Date(message.inserted_at))}
                    show={dateTooltipId === message.id}
                  >
                    <p
                      class="text-xs text-neutral-500"
                      onMouseEnter={() => setDateTooltipId(message.id)}
                      onMouseLeave={() => setDateTooltipId(undefined)}
                    >
                      {formatDateToHour(new Date(message.inserted_at))}
                    </p>
                  </Tooltip>
                </div>
              </div>
              <Tooltip tooltip="Report" show={reportTooltipId === message.id}>
                <button
                  class={classNames(
                    "rounded-full flex items-center justify-center p-2 hover:bg-stone-200",
                    { invisible: message.flagged }
                  )}
                  disabled={message.flagged}
                  onClick={() => flagMessage(message.id)}
                  onMouseEnter={() => setReportTooltipId(message.id)}
                  onMouseLeave={() => setReportTooltipId(undefined)}
                >
                  <span class="w-4 h-4 text-red-400 hero-flag" />
                </button>
              </Tooltip>
            </div>
            <div class="dark:text-neutral-400 break-all glitch-markdown">
              {message.body}
            </div>
          </li>
        ))}
      </ul>

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
    </div>
  );
}

function formatDateToHour(date: Date) {
  const formattedDate = new Intl.DateTimeFormat("en-GB", {
    hour: "2-digit",
    minute: "2-digit",
  }).format(date);

  return formattedDate;
}

function formatDate(date: Date) {
  const formattedDate = new Intl.DateTimeFormat("en-GB", {
    day: "2-digit",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).format(date);

  return formattedDate.replace("at ", "");
}
