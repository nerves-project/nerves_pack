defmodule NervesPack.NodeTest do
  use ExUnit.Case, async: true

  alias VintageNet.PropertyTable, as: PropTable

  @ip "192.168.0.1"

  describe "start/2" do
    setup do
      formatted = VintageNet.IP.ip_to_tuple!(@ip)
      PropTable.put(VintageNet, ["interface", "eth0", "addresses"], [%{address: formatted}])

      {:ok, hostname} = :inet.gethostname()

      %{hostname: hostname}
    end

    test "default", %{hostname: hostname} do
      NervesPack.Node.start(:test, force: true)

      assert node() == :"test@#{hostname}.local"
    end

    test "IP" do
      NervesPack.Node.start(:test, host: :ip, force: true)

      assert node() == :"test@#{@ip}"
    end

    test "dchp", %{hostname: hostname} do
      NervesPack.Node.start(:test, host: :dhcp, force: true)

      assert node() == :"test@#{hostname}"
    end

    test "mdns", %{hostname: hostname} do
      NervesPack.Node.start(:test, host: :mdns, force: true)

      assert node() == :"test@#{hostname}.local"
    end

    test "hostname", %{hostname: hostname} do
      NervesPack.Node.start(:test, host: :hostname, force: true)

      assert node() == :"test@#{hostname}.local"
    end

    test "full node name" do
      NervesPack.Node.start(:"full@nerves.local", force: true)

      assert node() == :"full@nerves.local"
    end

    test "various node name types", %{hostname: hostname} do
      # binary
      NervesPack.Node.start("howdy", force: true)

      assert node() == :"howdy@#{hostname}.local"

      # atom
      NervesPack.Node.start(:howdy, force: true)

      assert node() == :"howdy@#{hostname}.local"

      # charlist
      NervesPack.Node.start('howdy', force: true)

      assert node() == :"howdy@#{hostname}.local"
    end

    test "errors with nil node name" do
      assert NervesPack.Node.start(nil) ==
               {:error, "Bad node: nil"}
    end
  end
end
