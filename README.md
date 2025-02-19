# Hex MCP Server

A Model Context Protocol (MCP) server that provides real-time Hex package version information to AI tools like Cursor. This service helps ensure that AI-assisted development uses the correct and most up-to-date package versions when adding dependencies to Elixir projects.

## What is MCP?

The Model Context Protocol (MCP) is an open protocol that standardizes how applications provide context to Large Language Models (LLMs). Think of it like a USB-C port for AI applications. For more information about MCP, visit the [official documentation](https://modelcontextprotocol.io/introduction).

## Using with Cursor

Cursor supports MCP servers out of the box. To get accurate Hex package version suggestions in your Elixir projects, add this server to your Cursor configuration.

### Server URL

```
https://hex-mcp.9elements.com/sse
```

For detailed setup instructions, visit the [Cursor MCP documentation](https://docs.cursor.com/context/model-context-protocol#model-context-protocol).

## Development Setup

To start your Phoenix server locally:

1. Run `mix setup` to install and setup dependencies
2. Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
3. Visit [`localhost:4000`](http://localhost:4000) from your browser

## Production Deployment

For production deployment instructions, please refer to the [Phoenix deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn More

- [Phoenix Framework Official Website](https://www.phoenixframework.org/)
- [Phoenix Documentation](https://hexdocs.pm/phoenix)
- [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
- [Phoenix Forum](https://elixirforum.com/c/phoenix-forum)

## Credits

Built with ❤️ by [Daniel Hoelzgen](https://dhoelzgen.dev) from [9elements](https://9elements.com)

## Legal

- [Imprint](https://9elements.com/imprint)
- [Privacy Policy](https://9elements.com/imprint)
