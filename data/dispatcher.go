package data

import (
	"context"
	"encoding/json"
	"net/http"
	"os"
	"strings"

	"github.com/ppluuums-jp/cloud-sql-scheduler/domain"
	"github.com/ppluuums-jp/cloud-sql-scheduler/utils"

	"golang.org/x/exp/slog"
	sqladmin "google.golang.org/api/sqladmin/v1beta4"
)

type Dispatcher struct {
	ss *sqladmin.Service
	c  *http.Client
}

func NewDispatcher(ss *sqladmin.Service, c *http.Client) *Dispatcher {
	return &Dispatcher{
		ss: ss,
		c:  c,
	}
}

func (d *Dispatcher) Patch(ctx context.Context, ps domain.PubSubMessage) error {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))

	var m domain.Message
	err := json.Unmarshal(ps.Data, &m)
	if err != nil {
		return err
	}
	logger.Info("Request received for Cloud SQL instances",
		slog.String("severity", "INFO"),
	)

	err = utils.ValidateAction(m.Action)
	if err != nil {
		return err
	}

	instanceNames := strings.Split(m.Instance, ",")
	for _, instanceName := range instanceNames {
		rb := &sqladmin.DatabaseInstance{
			Settings: &sqladmin.Settings{
				ActivationPolicy: utils.GetAction(m.Action),
			},
		}
		_, err := d.ss.Instances.Patch(m.Project, instanceName, rb).Context(ctx).Do()
		if err != nil {
			return err
		}
		logger.Info("Instance patched",
			slog.String("severity", "INFO"),
		)
	}
	return nil
}
