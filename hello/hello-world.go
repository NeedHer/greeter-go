package hello

import "fmt"

type HelloWorld struct {
	name string
}

func NewHelloWorld(user string) *HelloWorld {
	return &HelloWorld{name: user}
}

func (h *HelloWorld) Hello() string {
	return fmt.Sprintf("Hello %s from Go library!", h.name)
}

func (h *HelloWorld) SayHello() {
	message := h.Hello()
	fmt.Println(message)
}
