import { h } from "preact";
import ChatForm from "./chat-form";
import { SendMessageResultPayload } from "./types";
import ChatList from "./chat-list";
import classNames from "classnames";

type Message = {
  id: number;
  author: string;
  body: string;
  inserted_at: string;
  flagged: boolean;
};

type Props = {
  messages: Message[];
  maxMessageLength: number;
  slowModeSec: number;
  maxBodyLength: number;
  maxAuthorLength: number;
  role: "user" | "streamer";

  sendMessage: (
    message: Omit<Message, "id">,
    callback: (reply: SendMessageResultPayload) => void
  ) => void;
  flagMessage: (messageId: number) => void;
  deleteMessage: (messageId: number) => void;
  messageSentListener: (listener: (message: Message) => void) => void;
  messageFlaggedListener: (listener: (payload: { id: number }) => void) => void;
  messageUnflaggedListener: (
    listener: (payload: { id: number }) => void
  ) => void;
  messageDeletedListener: (listener: (payload: { id: number }) => void) => void;
};

export function Chat({
  role,
  messages: initialMessages,
  slowModeSec,
  maxBodyLength,
  maxAuthorLength,
  sendMessage,
  deleteMessage,
  messageSentListener,
  messageFlaggedListener,
  flagMessage,
  messageDeletedListener,
  messageUnflaggedListener,
}: Props) {
  return (
    <div
      class={classNames("rounded-lg h-full flex flex-col", {
        "border border-indigo-200 dark:border-zinc-800": role === "user",
      })}
    >
      <div
        class={classNames(
          "py-4 px-8 border-b border-indigo-200 text-center dark:border-zinc-800 dark:text-neutral-400",
          {
            hidden: role === "streamer",
            "hidden lg:block": role === "user",
          }
        )}
      >
        Chat
      </div>
      <div
        class={classNames(
          "p-2 text-center text-xs border-b-[1px] border-indigo-200 dark:border-zinc-800 dark:text-neutral-400",
          {
            hidden: role === "streamer",
          }
        )}
      >
        This is not an official ElixirConf EU chat, so if you have any questions
        for the speakers, please ask them under the SwapCard stream.
      </div>
      <ChatList
        role={role}
        flagMessage={flagMessage}
        initialMessages={initialMessages}
        messageFlaggedListener={messageFlaggedListener}
        messageDeletedListener={messageDeletedListener}
        messageSentListener={messageSentListener}
        deleteMessage={deleteMessage}
        messageUnflaggedListener={messageUnflaggedListener}
      />
      <ChatForm
        maxBodyLength={maxBodyLength}
        maxAuthorLength={maxAuthorLength}
        slowModeSec={slowModeSec}
        sendMessage={sendMessage}
      />
    </div>
  );
}
