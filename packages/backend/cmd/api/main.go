package main

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	stdhttp "net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"app-template/packages/backend/internal/app"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	if err := run(logger); err != nil {
		logger.Error("api runtime failed", slog.Any("error", err))
	}
}

func run(logger *slog.Logger) error {
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)

	runtime, err := app.NewProductRuntime(ctx)
	if err != nil {
		stop()
		return fmt.Errorf("build runtime: %w", err)
	}
	// runtime 初期化後は InitLogger が差し替えた default logger を使い、起動・停止ログを stdout と OTLP の両方へ送る。
	logger = slog.Default()
	defer stop()
	defer func() {
		if closeErr := runtime.Close(context.Background()); closeErr != nil {
			logger.Error("close runtime", slog.Any("error", closeErr))
		}
	}()

	server := runtime.Server()

	go func() {
		<-ctx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if shutdownErr := server.Shutdown(shutdownCtx); shutdownErr != nil {
			logger.Error("shutdown server", slog.Any("error", shutdownErr))
		}
	}()

	logger.Info("app-template api listening", slog.String("addr", runtime.Config().Port))
	if err := server.ListenAndServe(); err != nil && !errors.Is(err, stdhttp.ErrServerClosed) {
		return fmt.Errorf("listen and serve: %w", err)
	}

	return nil
}
