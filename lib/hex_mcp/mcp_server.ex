defmodule HexMcp.McpServer do
  use MCPServer

  require Logger

  @protocol_version "2024-11-05"

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
    case validate_protocol_version(params["protocolVersion"]) do
      :ok ->
        {:ok,
         %{
           jsonrpc: "2.0",
           id: request_id,
           result: %{
             protocolVersion: @protocol_version,
             capabilities: %{
               tools: %{
                 listChanged: false
               }
             },
             serverInfo: %{
               name: "Hex Package MCP Server",
               version: "0.1.0"
             },
             tools: tools_list()
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
         tools: tools_list()
       }
     }}
  end

  @impl true
  def handle_call_tool(
        request_id,
        %{"name" => "hex_version_info", "arguments" => %{"package_name" => package_name}}
      ) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: get_hex_package_version(package_name)
           }
         ]
       }
     }}
  end

  def handle_call_tool(request_id, %{"name" => unknown_tool}) do
    {:error,
     %{
       jsonrpc: "2.0",
       id: request_id,
       error: %{
         code: -32601,
         message: "Method not found",
         data: %{
           name: unknown_tool
         }
       }
     }}
  end

  defp get_hex_package_version(package_name) when not is_binary(package_name),
    do: "Invalid package name"

  defp get_hex_package_version(package_name) when byte_size(package_name) < 2,
    do: "Invalid package name"

  defp get_hex_package_version(package_name) when byte_size(package_name) > 60,
    do: "Invalid package name"

  defp get_hex_package_version(package_name) do
    if package_name =~ ~r/^[a-z0-9\-\_\.]+$/ do
      try do
        case HTTPoison.get("https://hex.pm/api/packages/#{package_name}") do
          {:ok, %HTTPoison.Response{body: body}} ->
            decoded = Jason.decode!(body)
            [first_release | _] = decoded["releases"]
            first_release["version"]

          {:error, _} ->
            "Unknown package"
        end
      rescue
        error ->
          Logger.error("Error getting hex package version: #{inspect(error)}")
          "An error occured"
      end
    else
      "Invalid package name"
    end
  end

  defp tools_list() do
    [
      %{
        name: "hex_version_info",
        description:
          "Returns the latest version of the hex package. Use it to check for the latest heck package version when installing new Elixir dependencies",
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
  end
end
