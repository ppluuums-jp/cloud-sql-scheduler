package domain

import "context"

type MessageServce interface {
	Patch(ctx context.Context, m PubSubMessage) error
}

type Service struct {
	repo MessageRepository
}

func NewService(repo MessageRepository) *Service {
	return &Service{
		repo: repo,
	}
}

func (s *Service) Patch(ctx context.Context, m PubSubMessage) error {
	if err := s.repo.Patch(ctx, m); err != nil {
		return err
	}
	return nil
}
