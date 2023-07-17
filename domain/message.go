package domain

type PubSubMessage struct {
	Data []byte `json:"data"`
}

type Message struct {
	Instance string
	Project  string
	Action   string
}
