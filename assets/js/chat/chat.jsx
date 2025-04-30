import classNames from "classnames";
import { useState } from "preact/hooks";

const slowModeDelayS = 1;

export function Chat() {
  const [currentTab, setCurrentTab] = useState("chat");
  const [role, setRole] = useState("user");
  const [slowMode, setSlowMode] = useState(true);
  const [messages, setMessages] = useState([]);
  const [joined, setJoined] = useState(true);
  const [showEmojiOverlay, setShowEmojiOverlay] = useState(false);
  const [maxNicknameLength, setMaxNicknameLength] = useState(20);
  const [maxMsgLength, setMsgLength] = useState(20);
  const [author, setAuthor] = useState("");
  const [msgBody, setMsgBody] = useState("");

  return (
    <>
      <div
        class={classNames("justify-between flex-col", {
          flex: currentTab === "chat",
          hidden: currentTab !== "chat",
          "h-[0px] flex-grow": role === "admin",
          "h-full rounded-lg border border-indigo-200 dark:border-zinc-800":
            role === "user",
        })}
      >
        {role === "user" && (
          <div class="py-4 px-8 border-b border-indigo-200 text-center dark:border-zinc-800 dark:text-neutral-400 hidden lg:block">
            Chat
          </div>
        )}
        <div
          class={classNames({
            "p-2 text-center text-xs border-b-[1px] border-indigo-200 dark:border-zinc-800 dark:text-neutral-400":
              role === "user",
            hidden: role !== "user",
          })}
        >
          This is not an official ElixirConf EU chat, so if you have any
          questions for the speakers, please ask them under the SwapCard stream.
        </div>
        <ul class="overflow-y-auto flex-grow flex flex-col" id="message_box">
          {messages.map((msg) => (
            <li
              id={`${msg.id}-msg`}
              class={classNames(
                "group flex flex-col gap-1 px-6 py-4 relative message_box__element",
                {
                  "bg-red-100 hover:bg-red-200 dark:bg-red-900 dark:hover:bg-red-800":
                    msg.flagged && role === "user",
                  "hover:bg-stone-100 dark:hover:bg-stone-800": !msg.flagged,
                }
              )}
            >
              <div class="flex gap-4 justify-between items-center">
                <div class="flex gap-4 items-center">
                  <p class="text-indigo-800 text-sm text-medium dark:text-indigo-400">
                    {msg.author}
                  </p>
                </div>
                <div class={classNames({ "opacity-0": msg.flagged })}></div>
              </div>
              <div class="dark:text-neutral-400 break-all glitch-markdown">
                {msg.body}
              </div>
              <div
                class={classNames("hidden gap-4 items-center *:flex-1 mt-4", {
                  "group-hover:flex": role === "admin",
                })}
              >
                <button
                  class="bg-red-600 text-white rounded-lg py-1"
                  phx-click="delete_message"
                  phx-value-message-id={msg.id}
                >
                  Delete
                </button>
              </div>
            </li>
          ))}
        </ul>
        <form
          phx-change="validate-form"
          phx-submit="submit-form"
          class="border-t border-indigo-200 p-6 dark:border-zinc-800"
        >
          <div class="flex items-end gap-2 relative mb-2">
            <div class="flex flex-col relative w-full">
              <div class="flex justify-between min-h-[16px] mt-[-14px] mb-[2px]">
                <div
                  class={[
                    role == "admin" && "hidden",
                    "text-xs",
                    slowMode && "text-rose-600",
                    !slowMode && "text-neutral-400 dark:text-neutral-700",
                  ]}
                >
                  Slow Mode {slowModeDelayS} s.
                </div>
                <div></div>
                <div
                  class={[
                    "text-xs text-neutral-400 dark:text-neutral-700",
                    msgBody.length < maxMsgLength - 50 && "hidden",
                    msgBody.length == maxMsgLength &&
                      "text-rose-600 dark:text-rose-600",
                  ]}
                >
                  {msgBody.length}/{maxMsgLength}
                </div>
              </div>
              <textarea
                class="glitch-input-primary resize-none h-[96px] w-full dark:text-neutral-400"
                placeholder="Your message"
                maxlength={maxMsgLength}
                name="body"
                disabled={!joined}
                id="message_body"
              >
                {msgBody}
              </textarea>
            </div>
            <div class="relative">
              <button
                type="button"
                class="border border-indigo-200 rounded-lg px-2 py-1 disabled:opacity-50 dark:text-neutral-400 dark:border-zinc-800 dark:bg-zinc-800"
                phx-click="toggle-emoji-overlay"
                disabled={!joined}
              >
                Emoji
                {/* <.icon name="hero-face-smile" /> */}
              </button>

              <div
                class={classNames("absolute bottom-[calc(100%+4px)] right-0", {
                  hidden: !showEmojiOverlay,
                })}
                id="emoji-picker-container"
                phx-click-away="hide-emoji-overlay"
              >
                <emoji-picker class="light dark:hidden"></emoji-picker>
                <emoji-picker class="hidden dark:block dark"></emoji-picker>
              </div>
            </div>
          </div>
          <div class="flex flex-col sm:flex-row gap-2 mt-2">
            <div class="flex flex-1 relative">
              <input
                class="glitch-input-primary px-4 py-2"
                placeholder="Your nickname"
                maxlength={maxNicknameLength}
                name="author"
                value={author}
                disabled={!joined}
              />
              {!joined && (
                <div
                  class={[
                    "absolute bottom-[-18px] right-0 text-xs w-full text-neutral-400 dark:text-neutral-700",
                    author.length < maxNicknameLength - 5 && "hidden",
                    author.length == maxNicknameLength &&
                      "text-rose-600 dark:text-rose-600",
                  ]}
                >
                  {author.length}/{maxNicknameLength}
                </div>
              )}
            </div>
            <button
              type="submit"
              class="glitch-button-primary"
              disabled={author.length == 0}
            >
              {joined ? "Send" : "Join"}
            </button>
          </div>
        </form>
      </div>
    </>
  );
}
