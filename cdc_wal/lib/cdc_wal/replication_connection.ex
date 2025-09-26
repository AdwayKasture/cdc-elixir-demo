defmodule CdcWal.ReplicationConnection do
  use Postgrex.ReplicationConnection
  import CdcWal.Protocol
  alias CdcWal.Protocol.Decoder.Messages.Update
  alias CdcWal.Protocol.Decoder.Messages.Insert
  alias CdcWal.Protocol.Decoder
  alias CdcWal.Protocol.{KeepAlive,Write}

  def start_link(opts) do
    extra_opts = [auto_reconnect: true]
    Postgrex.ReplicationConnection.start_link(__MODULE__,:ok,opts++ extra_opts)
  end

  @impl true
  def init(:ok) do
    {:ok,%{step: :disconnected}}
  end

  @impl true
  def handle_connect(state) do
    query = "CREATE_REPLICATION_SLOT postgrex TEMPORARY LOGICAL pgoutput NOEXPORT_SNAPSHOT"
    {:query, query, %{state | step: :create_slot}}
  end

  @impl true
  def handle_result(results, %{step: :create_slot} = state) when is_list(results) do
    query = "START_REPLICATION SLOT postgrex LOGICAL 0/0 (proto_version '1', publication_names 'products_wal_pub')"
    {:stream, query, [], %{state | step: :streaming}}
  end

  ##write message 
  @impl true
  def handle_data(data, state) when is_write(data) do
    %Write{message: message} = parse(data)
    message
    |> Decoder.decode_message()
    |> case  do 
      %Insert{relation_id: relation_id,tuple_data: tuple}  -> IO.inspect({"inserted record for #{relation_id}",tuple}) 
      %Update{relation_id: relation_id,tuple_data: tuple} -> IO.inspect({"updated record for #{relation_id}",tuple})
      _ -> :ok
    end

    {:noreply, state}
  end

  ## keep alive 
  @impl true
  def handle_data(data, state) when is_keep_alive(data) do
    %KeepAlive{reply: reply, wal_end: wal_end} = parse(data)
    wal_end = wal_end + 1

    message =
      case reply do
        :now -> standby_status(wal_end, wal_end, wal_end, reply)
        :later -> hold()
      end
    {:noreply, message, state}
  end
end
