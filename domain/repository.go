package domain

import "context"

type MessageRepository interface {
	Patch(ctx context.Context, m PubSubMessage) error
}
