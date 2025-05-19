import { h, JSX } from "preact";
import { useEffect, useRef, useState } from "preact/hooks";
import classNames from "classnames";
import { Tooltip } from "./tooltip";
import "emoji-picker-element";
import ChatForm from "./chat-form";
import { SendMessageResultPayload } from "./types";

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
    callback: (reply: SendMessageResultPayload) => void
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
  const listRef = useRef<HTMLUListElement>(null);
  const [messages, setMessages] = useState(initialMessages);
  const [dateTooltipId, setDateTooltipId] = useState<number | undefined>();
  const [reportTooltipId, setReportTooltipId] = useState<number | undefined>();

  useEffect(() => {
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

  const scrollToBottom = () => {
    if (listRef) {
      listRef.current?.scrollTo(0, listRef.current.scrollHeight);
    }
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
            <div
              class="dark:text-neutral-400 break-all glitch-markdown"
              dangerouslySetInnerHTML={{ __html: message.body }}
            ></div>
          </li>
        ))}
      </ul>
      <ChatForm sendMessage={sendMessage} />
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
