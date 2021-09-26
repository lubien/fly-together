# FlyTogether

Fly.io has a handy GraphQL API we can use to both create and deploy apps.

For this proof of concept we will be deploying a livebook 
(using docker hub's [livebook/livebook](https://hub.docker.com/r/livebook/livebook) image) app using
only your fly auth token ([How to get a token?](https://fly.io/docs/flyctl/auth-token/)). 
I do not persist your token in any way, rest assurred.

This project was first conceived as I wanted to quickly create an online
livebook session me and a friend would be able to access together and 
eventually kill it when it was not useful anymore to us. <br>
    
For future features we consider:

- Choosing docker image by name</li>
- Setting secrects before deploying</li>
- Setting envyronment variables before deploying</li>
- [Any suggestions?](https://github.com/lubien/fly-together/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc)

## Credits

Much from this code was based on insights I've gained from FlyCtl CLI,
tweaking aroung the GraphQL playground and code from the dashboard example
so I have to be thankful for those who contributed to those projects.

- [GraphQL Playground](https://api.fly.io/graphql)
- [FlyCTl CLI](https://github.com/superfly/flyctl/tree/a79a76ad5b5b512f43ff6fe8a63d7d31ac3a031b/cmd)
- [Fly Hiring Dashboard](https://github.com/fly-hiring/phoenix-full-stack-work-sample)

## Running

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
