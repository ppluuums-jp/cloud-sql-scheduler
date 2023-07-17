package app

import (
	"context"
	"os"

	"github.com/ppluuums-jp/cloud-sql-scheduler/data"
	"github.com/ppluuums-jp/cloud-sql-scheduler/domain"

	"golang.org/x/exp/slog"
	"golang.org/x/oauth2/google"
	sqladmin "google.golang.org/api/sqladmin/v1beta4"
)

type App struct{}

func (a *App) Run(ctx context.Context, m domain.PubSubMessage) error {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	hc, err := google.DefaultClient(ctx, sqladmin.CloudPlatformScope)
	if err != nil {
		logger.Error("failed to create http client",
			slog.String("severity", "ERROR"),
			err,
		)
	}

	ss, err := sqladmin.New(hc)
	if err != nil {
		logger.Error("failed to create sqladmin service",
			slog.String("severity", "ERROR"),
			err,
		)
	}

	d := data.NewDispatcher(ss, hc)
	s := domain.NewService(d)
	if err := s.Patch(ctx, m); err != nil {
		logger.Error("failed to patch",
			slog.String("severity", "ERROR"),
			err,
		)
	}

	return nil
}
