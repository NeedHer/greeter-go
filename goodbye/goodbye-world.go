package goodbye

import "fmt"

type GoodbyeWorld struct {
	name string
}

func NewGoodbyeWorld(user string) *GoodbyeWorld {
	return &GoodbyeWorld{name: user}
}

func (g *GoodbyeWorld) Goodbye() string {
	return fmt.Sprintf("Goodbye %s from Go library!", g.name)
}

func (g *GoodbyeWorld) SayGoodbye() {
	message := g.Goodbye()
	fmt.Println(message)
}
