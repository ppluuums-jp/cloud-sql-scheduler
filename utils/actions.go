package utils

import "errors"

func GetAction(action string) string {
	switch action {
	case "start":
		return "ALWAYS"
	case "stop":
		return "NEVER"
	default:
		return "NEVER"
	}
}

func ValidateAction(action string) error {
	switch action {
	case "start", "stop":
		return nil
	default:
		return errors.New("Invalid action")
	}
}
