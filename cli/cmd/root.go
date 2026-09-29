package cmd

import (
	"fmt"
	"os"
	"runtime"

	"github.com/ente/cli/pkg"
	"github.com/spf13/cobra/doc"

	"github.com/spf13/viper"

	"github.com/spf13/cobra"
)

var version string

var ctrl *pkg.ClICtrl

var rootCmd = &cobra.Command{
	Use:   "ente",
	Short: "CLI tool for exporting your photos from Ente",
}

func GenerateDocs() error {
	return doc.GenMarkdownTree(rootCmd, "./docs/generated")
}

func Execute(controller *pkg.ClICtrl, ver string) {
	ctrl = controller
	version = ver
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	viper.SetConfigName("config")
	viper.AddConfigPath(".")
	viper.ReadInConfig()
}

func recoverWithLog() {
	if r := recover(); r != nil {
		fmt.Println("Panic occurred:", r)
		stackTrace := make([]byte, 1024*8)
		stackTrace = stackTrace[:runtime.Stack(stackTrace, false)]
		fmt.Printf("Stack Trace:\n%s", stackTrace)
	}
}
