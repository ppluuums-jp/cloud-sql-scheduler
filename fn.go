package fn

import (
	"context"

	"github.com/ppluuums-jp/cloud-sql-scheduler/app"
	"github.com/ppluuums-jp/cloud-sql-scheduler/domain"
)

func Fn(ctx context.Context, m domain.PubSubMessage) error {
	app := &app.App{}
	app.Run(ctx, m)
	return nil
}
