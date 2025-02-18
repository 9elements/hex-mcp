defmodule HexMcp.McpServer do
  use MCPServer

  require Logger

  @protocol_version "2025-02-19"

  @impl true
  def handle_ping(request_id) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: "pong"
     }}
  end

  @impl true
  def handle_initialize(request_id, params) do
    Logger.info("Client initialization params: #{inspect(params, pretty: true)}")

    case validate_protocol_version(params["protocolVersion"]) do
      :ok ->
        # Only include capabilities for implemented callbacks
        {:ok,
         %{
           jsonrpc: "2.0",
           id: request_id,
           result: %{
             protocolVersion: @protocol_version,
             capabilities: %{
               tools: %{
                 listChanged: true
               }
             },
             serverInfo: %{
               name: "SSH Hex Package MCP Server",
               version: "0.1.0"
             }
           }
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def handle_list_tools(request_id, _params) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         tools: [
           %{
             name: "hex_version_info",
             description: "Returns the latest version of the hex package",
             inputSchema: %{
               type: "object",
               required: ["package_name"],
               properties: %{
                 package_name: %{
                   type: "string",
                   description: "The name of the hex package"
                 }
               }
             },
             outputSchema: %{
               type: "object",
               required: ["version"],
               properties: %{
                 version: %{
                   type: "string",
                   description: "The latest version of the hex package"
                 }
               }
             }
           }
         ]
       }
     }}
  end

  @impl true
  def handle_call_tool(
        request_id,
        %{"name" => "hex_version_info", "arguments" => %{"package_name" => package_name}} = params
      ) do
    Logger.debug("Handling hex_version_info tool call with params: #{inspect(params)}")

    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             version: get_hex_package_version(package_name)
           }
         ]
       }
     }}
  end

  defp get_hex_package_version(package_name) do
    try do
      case HTTPoison.get("https://hex.pm/api/packages/#{package_name}") do
        {:ok, %HTTPoison.Response{body: body}} ->
          decoded = Jason.decode!(body)
          [first_release | _] = decoded["releases"]
          first_release["version"]

        {:error, _} ->
          "Unknown"
      end
    rescue
      _ ->
        "Unknown"
    end
  end
end
