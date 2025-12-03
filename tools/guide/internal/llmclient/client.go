package llmclient

import (
	"context"
	"io"

	openai "github.com/sashabaranov/go-openai"
)

func NewClient(baseURL string) *openai.Client {
	cfg := openai.DefaultConfig("") // no key for local server
	cfg.BaseURL = baseURL + "/v1"
	return openai.NewClientWithConfig(cfg)
}

// StreamChat streams tokens; call cb for each new chunk (delta).
func StreamChat(ctx context.Context, c *openai.Client, system, user, model string, cb func(token string)) error {
	req := openai.ChatCompletionRequest{
		Model: model, // e.g. "qwen2.5:ins-7b" if your server exposes that name; on llama.cpp often "llama" or a specific alias
		Messages: []openai.ChatCompletionMessage{
			{Role: openai.ChatMessageRoleSystem, Content: system},
			{Role: openai.ChatMessageRoleUser, Content: user},
		},
		Stream: true,
	}
	
	stream, err := c.CreateChatCompletionStream(ctx, req)
	if err != nil {
		return err
	}
	defer stream.Close()

	for {
		resp, err := stream.Recv()
		if err != nil {
			// End of stream is normal
			if err == io.EOF {
				break
			}
			return err
		}
		
		for _, choice := range resp.Choices {
			if choice.Delta.Content != "" {
				cb(choice.Delta.Content)
			}
		}
	}
	
	return nil
}
