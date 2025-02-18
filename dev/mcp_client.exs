# Simple MCP client script to demonstrate protocol flow
Mix.install([
  {:httpoison, "~> 1.8"},  # Using 1.x version to be compatible with eventsource_ex
  {:jason, "~> 1.4"},
  {:eventsource_ex, "~> 1.1.0"}
])

defmodule MCPClient do
  require Logger

  def run do
    HTTPoison.start()  # Start the HTTP client

    IO.puts("\n=== MCP Client Demo ===\n")

    # Step 1: Connect to SSE endpoint
    IO.puts("Connecting to SSE endpoint...")
    {:ok, _pid} = EventsourceEx.new("http://localhost:4000/sse", stream_to: self())

    # Wait for endpoint URL
    receive do
      %EventsourceEx.Message{event: "endpoint", data: endpoint} ->
        IO.puts("✓ Connected! Received endpoint: #{endpoint}\n")
        session_id = extract_session_id(endpoint)
        continue_flow(session_id)
      after 5000 ->
        IO.puts("✗ Failed to receive endpoint URL")
        System.halt(1)
    end
  end

  defp continue_flow(session_id) do
    # Step 2: Initialize connection
    IO.puts("Initializing connection...")
    init_request = %{
      jsonrpc: "2.0",
      id: "init-1",
      method: "initialize",
      params: %{
        protocolVersion: "2024-11-05",
        capabilities: %{}
      }
    }

    post_message(session_id, init_request)

    # Wait for initialize response
    receive do
      %EventsourceEx.Message{event: "message", data: data} ->
        response = Jason.decode!(data)
        IO.puts("✓ Server initialized with capabilities:")
        IO.puts("  - Protocol version: #{response["result"]["protocolVersion"]}")
        IO.puts("  - Server name: #{response["result"]["serverInfo"]["name"]}\n")
      after 5000 ->
        IO.puts("✗ Failed to receive initialize response")
        System.halt(1)
    end

    # Step 3: Send initialized notification
    IO.puts("Sending initialized notification...")
    init_notification = %{
      jsonrpc: "2.0",
      method: "notifications/initialized"
    }

    post_message(session_id, init_notification)
    IO.puts("✓ Sent initialized notification\n")

    # Step 4: List available tools
    IO.puts("Requesting available tools...")
    list_tools_request = %{
      jsonrpc: "2.0",
      id: "list-1",
      method: "tools/list"
    }

    post_message(session_id, list_tools_request)

    # Wait for tools list
    receive do
      %EventsourceEx.Message{event: "message", data: data} ->
        response = Jason.decode!(data)
        tools = response["result"]["tools"]
        IO.puts("✓ Available tools:")
        Enum.each(tools, fn tool ->
          IO.puts("  - #{tool["name"]}: #{tool["description"]}")
        end)
        IO.puts("")
      after 5000 ->
        IO.puts("✗ Failed to receive tools list")
        System.halt(1)
    end

    # Step 5: Call the hex_version_info tool
    IO.puts("Calling hex_version_info tool...")
    call_tool_request = %{
      jsonrpc: "2.0",
      id: "call-1",
      method: "tools/call",
      params: %{
        name: "hex_version_info",
        arguments: %{
          package_name: "openai_ex"
        }
      }
    }

    post_message(session_id, call_tool_request)

    # Wait for tool response
    receive do
      %EventsourceEx.Message{event: "message", data: data} ->
        response = Jason.decode!(data)
        [content_item | _] = response["result"]["content"]
        IO.puts("✓ Tool response:")
        IO.puts("  Input: openai_ex")
        IO.puts("  Output: #{content_item["version"]}\n")
      after 5000 ->
        IO.puts("✗ Failed to receive tool response")
        System.halt(1)
    end

    # Step 6: Test unknown method
    IO.puts("Testing unknown method ($/listTools)...")
    unknown_method_request = %{
      jsonrpc: "2.0",
      id: "unknown-1",
      method: "$/listTools"
    }

    post_message(session_id, unknown_method_request)

    # Wait for error response
    receive do
      %EventsourceEx.Message{event: "message", data: data} ->
        response = Jason.decode!(data)
        IO.puts("✓ Server responded with expected error:")
        IO.puts("  Code: #{response["error"]["code"]}")
        IO.puts("  Message: #{response["error"]["message"]}")
        if response["error"]["data"], do: IO.puts("  Data: #{inspect(response["error"]["data"])}\n")
      after 5000 ->
        IO.puts("✗ Failed to receive error response")
        System.halt(1)
    end

    IO.puts("=== Demo Complete ===")
    IO.puts("All steps completed successfully!")
  end

  defp post_message(session_id, payload) do
    url = "http://localhost:4000/message?sessionId=#{session_id}"
    headers = [{"Content-Type", "application/json"}]
    body = Jason.encode!(payload)

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: 202}} -> :ok
      {:ok, %{status_code: 400, body: body}} ->
        # Parse and display error response for 400 status
        error = Jason.decode!(body)
        IO.puts("✗ Server returned error: #{inspect(error)}")
        :ok
      error ->
        IO.puts("✗ Failed to send message: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp extract_session_id(endpoint) do
    ~r/sessionId=([^&]+)/ |> Regex.run(endpoint) |> Enum.at(1)
  end
end

# Run the demo
MCPClient.run()
