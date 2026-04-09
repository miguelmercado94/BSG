import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

type Props = {
  content: string;
};

/**
 * Respuesta RAG con Markdown renderizado (listas, negritas, código inline).
 */
export function ChatMarkdown({ content }: Props) {
  return (
    <div className="chat-markdown">
      <ReactMarkdown remarkPlugins={[remarkGfm]}>{content}</ReactMarkdown>
    </div>
  );
}
