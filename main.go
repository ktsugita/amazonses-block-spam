package main

import (
	"context"
	"log/slog"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, sesEvent events.SimpleEmailEvent) (events.SimpleEmailDisposition, error) {
	for _, record := range sesEvent.Records {
		ses := record.SES
		slog.Info("amazonses-block-spam", "ses.Receipt", ses.Receipt)
		if ses.Receipt.VirusVerdict.Status == "FAIL" {
			slog.Info("amazonses-block-spam", "ses.Receipt.VirusVerdict.Status", ses.Receipt.VirusVerdict.Status)
			return events.SimpleEmailDisposition{Disposition: events.SimpleEmailContinue}, nil
		}
		if ses.Receipt.SpamVerdict.Status == "FAIL" {
			slog.Info("amazonses-block-spam", "ses.Receipt.SpamVerdict.Status", ses.Receipt.SpamVerdict.Status)
			return events.SimpleEmailDisposition{Disposition: events.SimpleEmailContinue}, nil
		}
		if ses.Receipt.VirusVerdict.Status == "FAIL" {
			slog.Info("amazonses-block-spam", "ses.Receipt.DMARCVerdict.Status", ses.Receipt.DMARCVerdict.Status)
			return events.SimpleEmailDisposition{Disposition: events.SimpleEmailContinue}, nil
		}
	}
	return events.SimpleEmailDisposition{Disposition: events.SimpleEmailStopRule}, nil
}

func main() {
	lambda.Start(handler)
}
