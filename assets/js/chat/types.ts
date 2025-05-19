export type Message = {
  id: number;
  author: string;
  body: string;
  inserted_at: string;
  flagged: boolean;
};

export type SendMessageResultPayload =
  | {
      action: "done";
      message: Message;
    }
  | {
      action: "delayed";
      delay: number;
    };
